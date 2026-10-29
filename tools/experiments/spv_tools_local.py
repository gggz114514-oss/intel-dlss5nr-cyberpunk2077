"""SPIR-V helpers shared by the F3-C32 fusion build: parse, patch, reflect.

Only what this stage needs: an instruction walker, an ordinal-indexed view of
OpExtInst Fma sites (used to reproduce the parent body's two typed NoContraction
decorations), a NoContraction inserter, and a storage-class reflection that
reports the workgroup/private byte totals the runner must honour.
"""
import struct

NO_CONTRACTION = 42


class Module:
    def __init__(self, path):
        self.path = path
        data = path.read_bytes()
        self.words = list(struct.unpack('<%dI' % (len(data) // 4), data))
        assert self.words[0] == 0x07230203, path
        self.bound = self.words[3]
        self.instructions = []          # (opcode, operands, first_word_index, word_count)
        i = 5
        while i < len(self.words):
            w = self.words[i]
            op, count = w & 0xffff, w >> 16
            assert count >= 1 and i + count <= len(self.words), (path, i, count)
            self.instructions.append((op, self.words[i + 1:i + count], i, count))
            i += count

    def result_ids(self):
        # OpName(5)/OpMemberName(6) carry a target id but produce nothing.
        out = []
        for op, ops, _, _ in self.instructions:
            if op in (5, 6):
                continue
            if op in (16, 17):       # OpString / OpLine
                continue
            if ops:
                out.append(ops[0])
        return out

    def ext_inst_fma_ordinals(self):
        """Ordinal index (among all OpExtInst Fma sites) -> result id."""
        order = []
        for op, ops, _, _ in self.instructions:
            if op == 12 and len(ops) >= 5 and ops[3] == 50:
                order.append(ops[1])
        return order

    def id_to_instruction(self):
        """Result id -> (opcode, operands).  Result ids sit at operand 0 for types
        (including the cooperative-matrix extension types), OpString,
        OpExtInstImport and OpLabel, and at operand 1 otherwise.  First
        definition wins: extension type opcodes have no result type operand and
        would otherwise shadow an earlier scalar type id."""
        out = {}
        for op, ops, _, _ in self.instructions:
            if not ops or op in (2, 3, 4, 5, 6, 8, 14, 15, 16, 17, 71, 72, 73, 74, 75, 77):
                continue
            if 19 <= op <= 39 or op in (7, 11, 248, 4456, 4457, 4458, 5358):
                out.setdefault(ops[0], (op, ops))
            elif len(ops) > 1:
                out.setdefault(ops[1], (op, ops))
        return out

    def defining_instruction(self, cid):
        """Instruction that produces `cid` (result id is operand 0 for types and
        labels, operand 1 elsewhere).

        RESULT_AT_ZERO_OPS names the opcodes whose result id is operand 0;
        RESULT_AT_ZERO_OPS plus result_id_of() decides whether an instruction
        produces a result at all.  Without that gate the plain "ops[1] == cid"
        test also matches non-result instructions such as OpSource, whose second
        operand is the GLSL version literal (450 in every module here), so any
        value whose result id happens to be 450 was misread as an OpSource and
        every structural signature built from it collapsed to ('op', 3).
        That is how the U09 F30 child (join helper 243 -> 136 instructions,
        every later result id shifted down by 88) landed one decorated site on
        result id 450.
        """
        for op, ops, _, _ in self.instructions:
            if not ops:
                continue
            if op in RESULT_AT_ZERO_OPS:
                if ops[0] == cid:
                    return op, ops
            elif result_id_of(op, ops) is not None and len(ops) > 1 and ops[1] == cid:
                return op, ops
        return None, None

    def const_or_signature(self, cid, depth=0):
        op, ops = self.defining_instruction(cid)
        if op == 43:
            return ('const', ops[2])
        return self.operand_signature(cid, max(depth - 1, 0))

    def operand_signature(self, cid, depth=2):
        """ID-free structural fingerprint of the value `cid`."""
        if depth == 0:
            return 'leaf'
        op, ops = self.defining_instruction(cid)
        if op is None:
            return 'missing'
        if op == 81:                                  # OpCompositeExtract
            inner_op, _ = self.defining_instruction(ops[2])
            return ('extract', ops[3], inner_op, self.operand_signature(ops[2], depth - 1))
        if op == 61:                                  # OpLoad
            return ('load', self.operand_signature(ops[2], depth - 1))
        if op == 65:                                  # OpAccessChain
            idx = tuple(self.const_or_signature(x, depth) for x in ops[3:])
            return ('accesschain', idx)
        if op == 12:                                  # OpExtInst
            return ('extinst', ops[3])
        if op == 71:                                  # unreachable (decorations)
            return ('decorate',)
        if 43 <= op <= 46 or op in (39, 40, 41, 42):
            return ('const',)
        return ('op', op)

    def fma_signature(self, result_id):
        op, ops = self.defining_instruction(result_id)
        assert op == 12 and ops[3] == 50, (result_id, op)
        return tuple(self.operand_signature(x) for x in ops[4:7])

    def type_size_bytes(self, type_id, pointer_size=8):
        by_id = self.id_to_instruction()

        def size(tid, seen=()):
            assert tid not in seen, 'recursive type'
            op, ops = by_id[tid]
            if op == 21:                                   # OpTypeInt [id, width, signed]
                return max(1, ops[1] // 8)
            if op == 22:                                   # OpTypeFloat [id, width]
                return max(1, ops[1] // 8)
            if op == 23:                                   # OpTypeVector [id, comp, count]
                return ops[2] * size(ops[1], seen + (tid,))
            if op == 24:                                   # OpTypeMatrix [id, col, count]
                return ops[2] * size(ops[1], seen + (tid,))
            if op == 28:                                   # OpTypeArray [id, elem, length-id]
                return self.const_int(ops[2]) * size(ops[1], seen + (tid,))
            if op == 32:                                   # OpTypePointer
                return pointer_size
            if op == 30:                                   # OpTypeStruct
                return sum(size(m, seen + (tid,)) for m in ops[1:])
            raise AssertionError('unsupported type %d (op %d)' % (tid, op))
        return size(type_id)

    def const_int(self, cid):
        by_id = self.id_to_instruction()
        op, ops = by_id[cid]
        assert op == 43, (cid, op)                         # OpConstant
        return ops[2]

    def storage_bytes(self):
        """{storage_class_name: bytes} over all OpVariable globals."""
        names = {0: 'UniformConstant', 1: 'Input', 2: 'Uniform', 3: 'Output',
                 4: 'Workgroup', 5: 'CrossWorkgroup', 6: 'Private', 7: 'Function',
                 8: 'Generic', 9: 'PushConstant'}
        totals = {}
        by_id = self.id_to_instruction()
        for op, ops, _, _ in self.instructions:
            if op != 59:                                    # OpVariable
                continue
            result_type, storage = ops[0], ops[2]
            ptr_op, ptr_ops = by_id[result_type]
            assert ptr_op == 32 and ptr_ops[1] == storage, (result_type, storage, ptr_op)
            key = names.get(storage, str(storage))
            try:
                size = self.type_size_bytes(ptr_ops[2])
            except Exception:
                size = None          # opaque/struct/forward types are irrelevant here
            totals.setdefault(key, {"count": 0, "bytes": 0, "unknown": 0})
            totals[key]["count"] += 1
            if size is None:
                totals[key]["unknown"] += 1
            else:
                totals[key]["bytes"] += size
        for key, value in totals.items():
            value["bytes"] = value["bytes"] if not value["unknown"] else None
        return totals

    def binding_ids(self):
        """binding -> result-id of the variable (only for uniform buffers)."""
        by_id = self.id_to_instruction()
        out = {}
        for op, ops, _, _ in self.instructions:
            if op != 71 or len(ops) < 3 or ops[1] != 33:     # OpDecorate Binding
                continue
            out[ops[2]] = ops[0]
        return out

    def name_of(self, cid):
        for op, ops, _, _ in self.instructions:
            if op == 5 and ops[0] == cid:
                return ops[1].to_bytes(4, 'little').split(b'\0')[0].decode()
        return None


def functions(module):
    """[(name, [(opcode, word_count), ...]), ...] for every defined function."""
    out = []
    cur = None
    for op, ops, _, count in module.instructions:
        if op == 54:
            cur = []
            out.append((None, cur))
        if cur is not None:
            cur.append((op, count))
        if op == 56:
            cur = None
    named = []
    for _, body in out:
        name = None
        for op, ops, _, _ in module.instructions:
            if op == 5 and body and ops[0] == body[0][1] and False:
                name = None
        named.append(body)
    return named


def subsequence(want, have):
    """Greedy in-order match of `want` inside `have`; returns (matched, total, first_miss)."""
    j = 0
    matched = 0
    first_miss = None
    for i, w in enumerate(want):
        found = False
        while j < len(have):
            if have[j] == w:
                j += 1
                matched += 1
                found = True
                break
            j += 1
        if not found:
            if first_miss is None:
                first_miss = i
            break
    return matched, len(want), first_miss


def skeleton(module, functions_only=True):
    """ID-free instruction skeleton: (opcode, word count) per instruction.

    functions_only skips the annotation/type/constant/global sections, which
    legitimately differ between the parent body and the fused module (extra
    bindings, longer push struct, extra shared arrays)."""
    out = []
    depth = 0
    for op, _, _, count in module.instructions:
        if op == 54:                                     # OpFunction
            depth += 1
        if not functions_only or depth:
            out.append((op, count))
        if op == 56:                                     # OpFunctionEnd
            depth -= 1
    return out


def subsequence_diff(want, have):
    """Extra instructions in `have` that the in-order match skipped."""
    j = 0
    extra = []
    for w in want:
        while j < len(have) and have[j] != w:
            extra.append(have[j])
            j += 1
        if j < len(have):
            j += 1
    extra.extend(have[j:])
    return extra


def skeleton_subsequence(parent, child):
    """Match the parent body's *largest* compiled function inside the child's
    largest function (the fused module defines the body stage plus the new
    entry point, and glslang is free to order the helper functions differently,
    so a whole-module linear walk is not meaningful)."""
    pf = max(functions(parent), key=len)
    cf = max(functions(child), key=len)
    return subsequence(pf, cf) + (len(pf), len(cf), subsequence_diff(pf, cf))


def align_subsequence(want, have):
    """In-order alignment: [(want_index, have_index), ...] for the matched items."""
    j = 0
    pairs = []
    for i, w in enumerate(want):
        while j < len(have) and have[j] != w:
            j += 1
        if j >= len(have):
            break
        pairs.append((i, j))
        j += 1
    return pairs


def code_instructions(module, function=None):
    """[(instruction_index, opcode, operands)] inside functions (or one function)."""
    out = []
    depth = 0
    for idx, (op, ops, _, _) in enumerate(module.instructions):
        if op == 54:
            depth += 1
        if depth:
            out.append((idx, op, ops))
        if op == 56:
            depth -= 1
    return out


def function_regions(module):
    """[[global instruction index, ...], ...] one list per defined function."""
    regions = []
    cur = None
    for idx, (op, _, _, _) in enumerate(module.instructions):
        if op == 54:
            cur = []
            regions.append(cur)
        if cur is not None:
            cur.append(idx)
        if op == 56:
            cur = None
    return regions


NO_RESULT_OPS = (0, 2, 3, 4, 5, 6, 8, 14, 15, 16, 17, 62, 63, 64, 71, 72, 73, 74, 75, 77,
                 84, 99, 246, 247, 249, 250, 251, 252, 253, 254, 255)
RESULT_AT_ZERO_OPS = tuple(range(19, 40)) + (7, 11, 248, 4456, 4457, 4458, 5358)


def result_id_of(op, ops):
    """Result id of an instruction, or None when the instruction produces none."""
    if not ops or op in NO_RESULT_OPS:
        return None
    if op in RESULT_AT_ZERO_OPS:
        return ops[0]
    return ops[1] if len(ops) > 1 else None


def decoration_pattern(module, region):
    """Local positions inside `region` that carry OpDecorate NoContraction."""
    decorated = set(no_contraction_ids(module))
    result_at = {}
    for idx, (op, ops, _, _) in enumerate(module.instructions):
        rid = result_id_of(op, ops)
        if rid is not None and rid in decorated:
            result_at[idx] = rid
    return {pos: idx for pos, idx in enumerate(region) if idx in result_at}


def transfer_decoration_pattern(parent, child, keep_ids):
    """Copy the parent module's whole NoContraction pattern onto `child`.

    Function regions are matched by their ID-free instruction skeleton: the
    sealed helper functions match exactly, the body stage matches as an in-order
    subsequence (the fused source adds four workgroup-memory stores).  `keep_ids`
    are the child's decorations in regions that have no parent counterpart (the
    newly written epilogue) and are preserved as compiled.
    """
    parent_regions = function_regions(parent)
    child_regions = function_regions(child)
    child_skel = {i: [(child.instructions[x][0], child.instructions[x][3]) for x in r]
                  for i, r in enumerate(child_regions)}
    parent_skel = {i: [(parent.instructions[x][0], parent.instructions[x][3]) for x in r]
                   for i, r in enumerate(parent_regions)}
    keep = set(keep_ids)
    mapping = []
    used = set()
    for pi, pregion in enumerate(parent_regions):
        pattern = decoration_pattern(parent, pregion)
        if not pattern:
            continue
        want = parent_skel[pi]
        target = None
        for ci, have in child_skel.items():
            if ci in used:
                continue
            if have == want:
                target = ci
                break
        if target is None:
            for ci, have in child_skel.items():
                if ci in used:
                    continue
                pairs = align_subsequence(want, have)
                if len(pairs) == len(want):
                    target = ci
                    break
        assert target is not None, ("no child function matches a decorated parent function", pi, len(want))
        used.add(target)
        cregion = child_regions[target]
        pairs = dict(align_subsequence(want, child_skel[target]))
        assert len(pairs) == len(want), (len(pairs), len(want))
        for pos in pattern:
            keep.add(child.instructions[cregion[pairs[pos]]][1][1] if False else
                     result_id_of(child.instructions[cregion[pairs[pos]]][0],
                                  child.instructions[cregion[pairs[pos]]][1]))
        mapping.append({"parent_function_index": pi, "child_function_index": target,
                        "parent_instructions": len(want), "child_instructions": len(child_skel[target]),
                        "pattern_size": len(pattern)})
    keep = {x for x in keep if x is not None}
    untouched = [ci for ci in range(len(child_regions)) if ci not in used]
    info = {"functions_mapped": len(mapping), "mapping": mapping,
            "child_functions_without_parent_counterpart": untouched,
            "child_own_decorations_outside_pattern": len(set(keep_ids)),
            "parent_decorations_total": len(no_contraction_ids(parent))}
    return sorted(keep), info


def collections_counter(values):
    counts = {}
    for v in values:
        counts[v] = counts.get(v, 0) + 1
    return [(k, v) for k, v in sorted(counts.items())]


def set_no_contraction(module, keep_result_ids, out_path):
    """Rewrite the module so that the NoContraction set is exactly `keep_result_ids`.

    Decorations the module already carries but that are not wanted are dropped;
    wanted ones it lacks are inserted right after the existing annotation stream.
    This is how the bound parent's own precision map was produced (its build
    removed 18 helper decorations and added two body ones on top of the raw
    compile), so the same operation is applied here to reproduce that map.
    """
    keep = sorted(set(keep_result_ids))
    existing = no_contraction_ids(module)
    present = set(existing)
    valid = set()
    for idx, (op, ops, _, _) in enumerate(module.instructions):
        rid = result_id_of(op, ops)
        if rid is not None:
            valid.add(rid)
    assert set(keep) <= valid, ("target id is not an instruction result",
                                sorted(set(keep) - valid)[:5])
    words = list(module.words[:5])
    removed, kept = [], []
    insertion = None
    for op, ops, i, count in module.instructions:
        if op == 71 and ops[1] == NO_CONTRACTION:
            if ops[0] in present and ops[0] in set(keep):
                words.extend(module.words[i:i + count])
                kept.append(ops[0])
            else:
                removed.append(ops[0])
            continue
        if insertion is None and op == 19:
            additions = [[(3 << 16) | 71, rid, NO_CONTRACTION] for rid in keep if rid not in present]
            words.extend(w for chunk in additions for w in chunk)
            insertion = len(removed)  # marker
        words.extend(module.words[i:i + count])
    assert insertion is not None, "no global section"
    out_path.write_bytes(struct.pack('<%dI' % len(words), *words))
    check = Module(out_path)
    got = no_contraction_ids(check)
    assert got == keep, (len(got), len(keep))
    return {"removed": removed, "kept": kept,
            "added": [rid for rid in keep if rid not in present],
            "size_delta_bytes": 4 * (len(keep) - len(existing))}


def no_contraction_ids(module):
    return sorted(ops[0] for op, ops, _, _ in module.instructions
                  if op == 71 and ops[1] == NO_CONTRACTION)


def _skeleton_of(module, regions):
    return {i: [(module.instructions[x][0], module.instructions[x][3]) for x in r]
            for i, r in enumerate(regions)}


def transfer_decoration_pattern_aligned(parent, child, keep_ids, verify=True):
    """Copy the parent's NoContraction pattern onto a *reduced* child.

    `transfer_decoration_pattern` requires the parent's compiled function to
    appear inside the child's as an in-order subsequence.  A fused kernel that
    replaces a parent load block with a call is the opposite case: the child is
    the parent minus instructions, plus a handful of its own.  The alignment
    here is a longest-matching-block alignment (difflib over the ID-free
    (opcode, word count) skeleton), which tolerates insertions and deletions on
    both sides; every mapped pair is then verified by comparing the two
    instructions' ID-free operand signatures, so a coincidental alignment of a
    repeated pattern cannot silently move a decoration.

    Returns (keep_result_ids, info) where the ids are the child's.
    """
    import difflib

    parent_regions = function_regions(parent)
    child_regions = function_regions(child)
    parent_skel = _skeleton_of(parent, parent_regions)
    child_skel = _skeleton_of(child, child_regions)
    keep = set(keep_ids)
    mapping = []
    used = set()
    for pi, pregion in enumerate(parent_regions):
        pattern = decoration_pattern(parent, pregion)
        if not pattern:
            continue
        want = parent_skel[pi]
        best = None
        for ci, have in child_skel.items():
            if ci in used or len(have) < 1:
                continue
            blocks = difflib.SequenceMatcher(None, want, have, autojunk=False) \
                .get_matching_blocks()
            matched = sum(b.size for b in blocks)
            pos = {}
            ok = True
            for b in blocks:
                for k in range(b.size):
                    pos[b.a + k] = b.b + k
            # every decorated parent position must be inside a matching block
            for p in pattern:
                if p not in pos:
                    ok = False
                    break
            if not ok:
                continue
            if best is None or matched > best[0]:
                best = (matched, ci, pos)
        assert best is not None, ("no child function aligns with a decorated parent "
                                 "function", pi, len(want))
        matched, target, pos = best
        used.add(target)
        cregion = child_regions[target]
        for p in sorted(pattern):
            pidx = pregion[p]
            cidx = cregion[pos[p]]
            pop, pops = parent.instructions[pidx][0], parent.instructions[pidx][1]
            cop, cops = child.instructions[cidx][0], child.instructions[cidx][1]
            assert pop == cop and parent.instructions[pidx][3] == child.instructions[cidx][3]
            if verify:
                prid = result_id_of(pop, pops)
                crid = result_id_of(cop, cops)
                assert prid is not None and crid is not None, (pidx, cidx)
                psig = parent.operand_signature(prid, 3)
                csig = child.operand_signature(crid, 3)
                assert psig == csig, ("mapped instructions differ", pi, p, psig, csig)
            keep.add(result_id_of(cop, cops))
        mapping.append({"parent_function_index": pi, "child_function_index": target,
                        "parent_instructions": len(want),
                        "child_instructions": len(child_skel[target]),
                        "matched_instructions": matched,
                        "pattern_size": len(pattern)})
    keep = {x for x in keep if x is not None}
    untouched = [ci for ci in range(len(child_regions)) if ci not in used]
    info = {"alignment": "longest-matching-blocks with operand-signature verification",
            "functions_mapped": len(mapping), "mapping": mapping,
            "child_functions_without_parent_counterpart": untouched,
            "child_own_decorations_outside_pattern": len(set(keep_ids)),
            "parent_decorations_total": len(no_contraction_ids(parent))}
    return sorted(keep), info
