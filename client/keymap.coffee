helpurls = require './helpurls'
window.onhelp = -> false # prevent IE from acting silly on F1

# utils
inherit = (x) -> (F = ->):: = x; new F # JavaScript's prototypal inheritance
join = (x) -> [].concat x... # ⊃,/
dict = (pairs) -> r = {}; (for [k, v] in pairs then r[k] = v); r # like in Python, build a dictionary from a list of pairs
chr = (x) -> String.fromCharCode x
ord = (x) -> x.charCodeAt 0

PK0 = '`' # default prefix key
@getPrefixKey = getPrefixKey = -> localStorage.prefixKey || PK0
@setPrefixKey = (x = PK0) ->
  if x != old = getPrefixKey()
    if x == PK0 then delete localStorage.prefixKey else localStorage.prefixKey = x
    m = CodeMirror.keyMap.dyalog; m["'#{x}'"] = m["'#{old}'"]; delete m["'#{old}'"]
  return

squiggleDescriptions = ((s) -> dict s.split(/\n| *│ */).map (l) -> [l[0], l[2..]]) '''
  ¨ each              │ ← assignment         │ ⊤ encode (123→1 2 3) │ ⌹ matrix inv/div
  ¯ negative          │ → branch             │ | abs/modulo         │ ⍷ find
  ∨ or (GCD)          │ ⍺ left argument      │ ⍝ comment            │ ⍨ commute
  ∧ and (LCM)         │ ⌈ ceil/max           │ ⍀ \\[⎕io]            │ ⍣ power operator
  × signum/times      │ ⌊ floor/min          │ ⌿ /[⎕io]             │ ⍞ char I/O
  ÷ reciprocal/divide │ ∇ recur              │ ⋄ statement sep      │ ⍬ zilde (⍳0)
  ? roll/deal         │ ∘ compose            │ ⌶ I-beam             │ ⍤ rank
  ⍵ right argument    │ ⎕ evaluated input    │ ⍒ grade down         │ ⌸ key
  ∊ enlist/membership │ ⍎ execute            │ ⍋ grade up           │ ⌷ default/index
  ⍴ shape/reshape     │ ⍕ format             │ ⌽ reverse/rotate     │ ≡ depth/match
  ~ not/without       │ ⊢ right              │ ⍉ transpose          │ ≢ tally/not match
  ↑ mix/take          │ ⊂ enclose/partition  │ ⊖ ⌽[⎕io]             │ ⊣ left
  ↓ split/drop        │ ⊃ disclose/pick      │ ⍟ logarithm          │ ⍪ table / ,[⎕io]
  ⍳ indices/index of  │ ∩ intersection       │ ⍱ nor                │ ⍠ variant
  ○ pi/trig           │ ∪ unique/union       │ ⍲ nand
  * exp/power         │ ⊥ decode (1 2 3→123) │ ! factorial/binomial
'''

ctid = 0 # backquote completion timeout id
@reverse = reverse = {} # reverse keymap: maps squiggles to their `x keys; used in lbar tooltips

CodeMirror.keyMap.dyalog = inherit fallthrough: 'default', F1: (cm) ->
  c = cm.getCursor(); s = cm.getLine(c.line).toLowerCase()
  u =
    if      m = /^ *(\)[a-z]+).*$/.exec s then helpurls[m[1]] || helpurls.WELCOME
    else if m = /^ *(\][a-z]+).*$/.exec s then helpurls[m[1]] || helpurls.UCMDS
    else
      x = s[s[...c.ch].replace(/.[áa-z]*$/i, '').length..].replace(/^([⎕:][áa-z]*|.).*$/i, '$1').replace /^:end/, ':'
      helpurls[x] ||
        if      x[0] == '⎕' then helpurls.SYSFNS
        else if x[0] == ':' then helpurls.CTRLSTRUCTS
        else                     helpurls.LANGELEMENTS
  w = screen.width / 4; h = screen.height / 4
  open u, 'help', "width=#{2 * w},height=#{2 * h},left=#{w},top=#{h},scrollbars=1,location=1,toolbar=0,menubar=0,resizable=1"
    .focus?()
  return

CodeMirror.keyMap.dyalog["'#{getPrefixKey()}'"] = (cm) ->
  cm.setOption 'autoCloseBrackets', false; cm.setOption 'keyMap', 'dyalogBackquote'
  c = cm.getCursor(); cm.replaceSelection getPrefixKey(), 'end'
  ctid = setTimeout(
    -> cm.showHint
      completeOnSingleClick: true
      extraKeys:
        Backspace: (cm, m) -> m.close(); cm.execCommand 'delCharBefore'; return
        Left:      (cm, m) -> m.close(); cm.execCommand 'goCharLeft'; return
        Right:     (cm, m) -> m.pick(); return
      hint: ->
        data = from: c, to: cm.getCursor(), list: bqc
        CodeMirror.on data, 'close', -> cm.setOption 'autoCloseBrackets', true; cm.setOption 'keyMap', 'dyalog'
        data
    500
  )

# `x completions
ks = '`1234567890-=qwertyuiop[]asdfghjk l;\'\\zxcvbnm,./~!@#$%^&*()_+QWERTYUIOP{}ASDFGHJKL:"|ZXCVBNM<>?'.split /\s*/
vs = '`¨¯<≤=≥>≠∨∧×÷?⍵∊⍴~↑↓⍳○*←→⍺⌈⌊_∇∆∘\'⎕⍎⍕ ⊢ ⊂⊃∩∪⊥⊤|⍝⍀⌿⋄⌶⍫⍒⍋⌽⍉⊖⍟⍱⍲!⌹?⍵⍷⍴⍨↑↓⍸⍥⍣⍞⍬⍺⌈⌊_∇∆⍤⌸⌷≡≢⊣⊂⊃∩∪⊥⊤|⍪⍙⍠'.split /\s*/
bqc = []
CodeMirror.keyMap.dyalogBackquote = nofallthrough: true, disableInput: true
if ks.length != vs.length then console.error? 'bad configuration of backquote keymap'
ks.forEach (k, i) ->
  v = vs[i]; reverse[v] ?= k
  bqc.push text: v, render: (e) -> $(e).text "#{v} #{getPrefixKey()}#{k} #{squiggleDescriptions[v] || ''}  "
  CodeMirror.keyMap.dyalogBackquote["'#{k}'"] = (cm) ->
    clearTimeout ctid; cm.state.completionActive?.close?(); cm.setOption 'keyMap', 'dyalog'; cm.setOption 'autoCloseBrackets', true
    c = cm.getCursor(); if k == getPrefixKey() then bqbqHint cm else cm.replaceRange v, {line: c.line, ch: c.ch - 1}, c
    return
ks = vs = null

bqc[0].render = (e) -> e.innerHTML = "  #{pk = getPrefixKey()}#{pk} <i>completion by name</i>"
bqc[0].hint = bqbqHint = (cm) ->
  c = cm.getCursor(); cm.replaceSelection getPrefixKey(), 'end'
  cm.showHint completeOnSingleClick: true, extraKeys: {Right: pick = ((cm, m) -> m.pick()), Space: pick}, hint: ->
    u = cm.getLine(c.line)[c.ch + 1...cm.getCursor().ch]
    a = []; for x in bqbqc when x.name[...u.length] == u then a.push x
    from: {line: c.line, ch: c.ch - 1}, to: cm.getCursor(), list: a
  return

# ``name completions
bqbqc = ((s) -> join s.split('\n').map (l) ->
  [squiggle, names...] = l.split ' '
  names.map (name) -> name: name, text: squiggle, render: (e) ->
    key = reverse[squiggle]; pk = getPrefixKey()
    $(e).text "#{squiggle} #{if key then pk + key else '  '} #{pk}#{pk}#{name}"
) """
  ← leftarrow assign gets
  + plus add conjugate mate
  - minus hyphen subtract negate
  × cross times multiply sgn signum direction
  ÷ divide reciprocal obelus
  * star asterisk power exponential
  ⍟ logarithm naturallogarithm circlestar starcircle splat
  ⌹ domino matrixdivide quaddivide
  ○ pi circular trigonometric
  ! exclamation bang shriek factorial binomial combinations
  ? question roll deal random
  | stile stroke verticalline modulo abs magnitude residue remainder
  ⌈ upstile maximum ceiling
  ⌊ downstile minimum floor
  ⊥ base decode uptack
  ⊤ antibase encode downtack representation
  ⊣ left lev lefttack
  ⊢ right dex righttack
  = equal
  ≠ ne notequal xor logicalxor
  ≤ le lessorequal fore
  < lessthan before
  > greaterthan after
  ≥ ge greaterorequal aft
  ≡ match equalunderbar identical
  ≢ notmatch equalunderbarslash notidentical tally
  ∧ and conjunction lcm logicaland lowestcommonmultiple caret
  ∨ or disjunction gcd vel logicalor greatestcommondivisor hcf highestcommonfactor
  ⍲ nand andtilde logicalnand carettilde
  ⍱ nor ortilde logicalnor
  ↑ uparrow mix take
  ↓ downarrow split drop
  ⊂ enclose leftshoe partition
  ⊃ disclose rightshoe pick
  ⌷ squishquad squad index default materialise
  ⍋ gradeup deltastile upgrade pine
  ⍒ gradedown delstile downgrade spine
  ⍳ iota indices indexof
  ⍷ find epsilonunderbar
  ∪ cup union unique downshoe distinct
  ∩ cap intersection upshoe
  ∊ epsilon in membership enlist flatten type
  ~ tilde not without
  / slash reduce fold insert select compress replicate solidus
  \\ backslash slope scan expand
  ⌿ slashbar reducefirst foldfirst insertfirst
  ⍀ slopebar backslashbar scanfirst expandfirst
  , comma catenate laminate ravel
  ⍪ commabar table catenatefirst
  ⍴ rho shape reshape
  ⌽ reverse rotate circlestile
  ⊖ reversefirst rotatefirst circlebar rowel upset
  ⍉ transpose circlebackslash cant
  ¨ each diaeresis
  ⍨ commute switch selfie tildediaeresis
  ⍣ poweroperator stardiaeresis
  . dot
  ∘ jot compose ring
  ⍤ jotdiaeresis rank paw
  ⍞ quotequad characterinput rawinput
  ⎕ quad input evaluatedinput
  ⍠ colonquad quadcolon variant option
  ⌸ equalsquad quadequals key
  ⍎ execute eval uptackjot hydrant
  ⍕ format downtackjot thorn
  ⋄ diamond statementseparator
  ⍝ comment lamp
  → rightarrow branch abort
  ⍵ omega rightarg
  ⍺ alpha leftarg
  ∇ del recur triangledown downtriangle
  & ampersand spawn et
  ¯ macron negative highminus
  ⍬ zilde empty
  ⌶ ibeam
  ¤ currency isolate
  ∥ parallel
  ∆ delta triangleup uptriangle
  ⍙ deltaunderbar
  ⍥ circlediaeresis hoof
  ⍫ deltilde
  á aacute
""" + [0...26].map((i) -> "\n#{chr i + ord 'Ⓐ'} _#{chr i + ord 'a'}").join '' # underscored alphabet: Ⓐ _a ...

'''
  [     0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F]
  [00] QT ER TB BT EP UC DC RC LC US DS RS LS UL DL RL
  [10] LL HO CT PT IN II DI DP DB RD TG DK OP CP MV FD
  [20] BK ZM SC RP NX PV RT RA ED TC NB NS ST EN IF HK
  [30] FX LN MC MR JP D1 D2 D3 D4 D5 U1 U2 U3 U4 U5 Lc
  [40] Rc LW RW Lw Rw Uc Dc Ll Rl Ul Dl Us Ds DD DH BH
  [50] BP AB HT TH RM CB PR SR -- TL UA AO DO GL CH PU
  [60] PA -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  [70] -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  [80] -- -- -- -- -- -- TO MO -- -- -- -- -- S1 S2 OS
'''.replace(/\[.*?\]/g, '').replace(/^\s*|\s*$/g, '').split(/\s+/).forEach (xx, i) ->
  if xx != '--'
    CodeMirror.keyMap.dyalog["'#{chr 0xf800 + i}'"] = xx
    CodeMirror.commands[xx] = (cm) -> (if (h = cm.dyalogCommands) && h[xx] then h[xx]()); return
  return

'''
  QT Shift-Esc
  ER Enter
  EP Esc
  FD Shift-Ctrl-Enter
  BK Shift-Ctrl-Backspace
  SC Ctrl-F
  ED Shift-Enter
  TC Ctrl-Enter
  TL Ctrl-Up
'''.split('\n').forEach (l) -> [xx, keys...] = l.split /\s+/; keys.forEach((key) -> CodeMirror.keyMap.dyalog[key] = xx); return
