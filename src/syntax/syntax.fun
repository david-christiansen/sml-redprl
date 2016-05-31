signature SYNTAX_VIEW =
sig
  type symbol
  type variable
  type metavariable
  type sort
  type 'a operator
  type 'a spine

  type term

  datatype 'a bview =
     \ of (symbol spine * variable spine) * 'a

  datatype 'a view =
     ` of variable
   | $ of symbol operator * 'a bview spine
   | $# of metavariable * ((symbol * sort) spine * 'a spine)

  val check : sort -> term view -> term
  val $$ : symbol operator * term bview spine -> term
  val out : term -> term view
end

functor AbtSyntaxView (Abt : ABT) : SYNTAX_VIEW =
struct
  open Abt
  type 'a operator = 'a Abt.O.t
  type term = abt
  fun check tau m = Abt.check (m, tau)
end

functor AstSyntaxView (Ast : AST where type 'a spine = 'a list) : SYNTAX_VIEW =
struct
  type symbol = Ast.symbol
  type variable = Ast.variable
  type metavariable = Ast.metavariable
  type sort = unit
  type 'a operator = 'a Ast.operator
  type 'a spine = 'a Ast.spine

  type term = Ast.ast

  datatype 'a bview =
     \ of (symbol spine * variable spine) * 'a

  datatype 'a view =
     ` of variable
   | $ of symbol operator * 'a bview spine
   | $# of metavariable * ((symbol * sort) spine * 'a spine)

  fun check () =
    fn `x => Ast.` x
     | $ (th, es) => Ast.$ (th, List.map (fn \ ((us,xs), m) => Ast.\ ((us, xs), m)) es)
     | $# (x, (us, ms)) => Ast.$# (x, (List.map #1 us, ms))

  fun $$ (th, es) = check () ($ (th, es))

  val out =
    fn Ast.`x => `x
     | Ast.$ (th, es) => $ (th, List.map (fn Ast.\ ((us, xs), m) => \ ((us, xs), m)) es)
     | Ast.$# (x, (us, ms)) => $# (x, (List.map (fn u => (u, ())) us, ms))
end

functor RedPrlSyntax (View : SYNTAX_VIEW where type 'a operator = 'a RedPrlOperator.t where type 'a spine = 'a list) =
struct

  open View

  structure O = RedPrlOperator
  structure RS = SortData

  datatype 'a view =
     CAPPROX of RS.sort * 'a * 'a
   | CEQUIV of RS.sort * 'a * 'a
   | BASE of RS.sort
   | TOP of RS.sort
   | UNIV of RS.sort
   | UNIV_GET_LVL of 'a
   | MEMBER of RS.sort * 'a * 'a
   | EQ of RS.sort * 'a * 'a * 'a
   | AX
   | SQUASH of RS.sort * 'a
   | DFUN of 'a * variable * 'a
   | FUN of 'a * 'a
   | NOT of 'a
   | LAM of variable * 'a
   | AP of 'a * 'a
   | DFUN_DOM of 'a
   | DFUN_COD of 'a * 'a
   | ENSEMBLE of RS.sort * RS.sort * 'a * variable * 'a
   | DEP_ISECT of 'a * variable * 'a
   | VOID

   | LBASE
   | LSUCC of 'a
   | LSUP of 'a * 'a

   | ATOM of RS.sort
   | TOKEN of symbol * RS.sort
   | IF_EQ of RS.sort * 'a * 'a * 'a * 'a

   | RCD_CONS of symbol * 'a * 'a
   | RCD_SINGL of symbol * 'a
   | RECORD_TY of symbol * 'a * 'a
   | RCD_PROJ of symbol * 'a
   | SINGL_GET_TY of 'a

   | REFINE_SCRIPT of RS.sort * 'a * 'a * 'a
   | EXTRACT_WITNESS of RS.sort * 'a
   | VEC_LITERAL of RS.sort * 'a list
   | STR_LITERAL of string
   | OPT_SOME of RS.sort * 'a
   | OPT_NONE of RS.sort

   | TAC_SEQ of 'a * (symbol * RS.sort) list * 'a
   | TAC_ORELSE of 'a * 'a
   | MTAC_ALL of 'a
   | MTAC_EACH of 'a list
   | MTAC_FOCUS of int * 'a
   | TAC_PROGRESS of 'a
   | TAC_REC of variable * 'a
   | TAC_INTRO of int option
   | TAC_EQ of int option
   | TAC_EXT
   | TAC_CUM
   | TAC_ELIM of symbol * RS.sort
   | TAC_HYP of symbol * RS.sort
   | TAC_UNHIDE of symbol * RS.sort
   | TAC_AUTO
   | TAC_ID
   | TAC_FAIL
   | TAC_TRACE of RS.sort * 'a
   | TAC_CSTEP of int
   | TAC_CEVAL
   | TAC_CSYM
   | TAC_REWRITE_GOAL of RS.sort * 'a
   | TAC_EVAL_GOAL of symbol option
   | TAC_NORMALIZE of symbol option
   | TAC_WITNESS of RS.sort * 'a
   | TAC_UNFOLD of symbol * symbol option
   | HYP_REF of symbol


  infix 3 $ $$
  infix 2 \

  local
    fun @@ (f, x) = f x
    infixr @@

    open RedPrlOperators

    fun ret tau m = O.RET tau $$ [([],[]) \ m]
    fun intoCttV th es = ret RS.EXP @@ O.V (CTT_V th) $$ es
    fun intoAtmV th es = ret RS.EXP @@ O.V (ATM_V th) $$ es
    fun intoRcdV th es = ret RS.EXP @@ O.V (RCD_V th) $$ es
    fun intoCttD th es = O.D (CTT_D th) $$ es
    fun intoRcdD th es = O.D (RCD_D th) $$ es
    fun intoTacV th es = ret RS.TAC @@ O.V (LCF th) $$ es
    fun intoMTacV th es = ret RS.MTAC @@ O.V (LCF th) $$ es
    fun cutCtt (sigma, tau) th es m = O.CUT (sigma, tau) $$ [([],[]) \ O.K (CTT_K th) $$ es, ([],[]) \ m]
    fun cutAtm (sigma, tau) th es m = O.CUT (sigma, tau) $$ [([],[]) \ O.K (ATM_K th) $$ es, ([],[]) \ m]
    fun cutLvl th es m = O.CUT (RS.LVL, RS.LVL) $$ [([],[]) \ O.K (LVL_K th) $$ es, ([],[]) \ m]
    fun cutRcd th es m = O.CUT (RS.EXP, RS.EXP) $$ [([],[]) \ O.K (RCD_K th) $$ es, ([],[]) \ m]
  in
    val rec into =
      fn CAPPROX (tau, m, n) => intoCttV (CttOperators.CAPPROX tau) [([],[]) \ m, ([],[]) \ n]
       | CEQUIV (tau, m, n) => intoCttV (CttOperators.CEQUIV tau) [([],[]) \ m, ([],[]) \ n]
       | BASE tau => intoCttV (CttOperators.BASE tau) []
       | TOP tau => intoCttV (CttOperators.TOP tau) []
       | UNIV tau => intoCttV (CttOperators.UNIV tau) []
       | UNIV_GET_LVL a => cutCtt (RS.EXP, RS.LVL) CttOperators.UNIV_GET_LVL [] a
       | MEMBER (tau, m, a) => intoCttV (CttOperators.MEMBER tau) [([],[]) \ m, ([],[]) \ a]
       | EQ (tau, m, n, a) => intoCttV (CttOperators.EQ tau) [([],[]) \ m, ([],[]) \ n, ([],[]) \ a]
       | AX => intoCttV CttOperators.AX []
       | SQUASH (tau, a) => intoCttV (CttOperators.SQUASH tau) [([],[]) \ a]
       | DFUN (a, x, bx) => intoCttV CttOperators.DFUN [([],[]) \ a, ([],[x]) \ bx]
       | FUN (a, b) => intoCttD CttOperators.FUN [([],[]) \ a, ([],[]) \ b]
       | NOT a => intoCttD CttOperators.NOT [([],[]) \ a]
       | ENSEMBLE (sigma, tau, a, x, bx) => intoCttV (CttOperators.ENSEMBLE (sigma, tau)) [([],[]) \ a, ([],[x]) \ bx]
       | LAM (x, mx) => intoCttV CttOperators.LAM [([],[x]) \ mx]
       | AP (m, n) => cutCtt (RS.EXP, RS.EXP) CttOperators.AP [([],[]) \ n] m
       | DFUN_DOM a => cutCtt (RS.EXP, RS.EXP) CttOperators.DFUN_DOM [] a
       | DFUN_COD (a, b) => cutCtt (RS.EXP, RS.EXP) CttOperators.DFUN_COD [([],[]) \ b] a
       | DEP_ISECT (a, x, bx) => intoCttV CttOperators.DEP_ISECT [([],[]) \ a, ([],[x]) \ bx]
       | VOID => intoCttV CttOperators.VOID []

       | LBASE => ret RS.LVL @@ O.V (LVL_V 0) $$ []
       | LSUCC m => cutLvl LevelOperators.LSUCC [] m
       | LSUP (m, n) => cutLvl LevelOperators.LSUP0 [([],[]) \ n] m

       | ATOM tau => intoAtmV (AtomOperators.ATOM tau) []
       | TOKEN (u, tau) => intoAtmV (AtomOperators.TOKEN (u, tau)) []
       | IF_EQ (tau, t1, t2, m, n) => cutAtm (RS.EXP, tau) (AtomOperators.TEST0 tau) [([],[]) \ t2, ([],[]) \ m, ([],[]) \ n] t1

       | RCD_CONS (u, m, n) => intoRcdV (RecordOperators.CONS u) [([],[]) \ m, ([],[]) \ n]
       | RCD_SINGL (u, m) => intoRcdV (RecordOperators.SINGL u) [([],[]) \ m]
       | RECORD_TY (u, a, b) => intoRcdD (RecordOperators.RECORD u) [([],[]) \ a, ([],[]) \ b]
       | RCD_PROJ (u, m) => cutRcd (RecordOperators.PROJ u) [] m
       | SINGL_GET_TY a => cutRcd RecordOperators.SINGL_GET_TY [] a

       | REFINE_SCRIPT (tau, m, s, e) => ret (RS.THM tau) @@ O.V (REFINE tau) $$ [([],[]) \ m, ([],[]) \ s, ([],[]) \ e]
       | EXTRACT_WITNESS (tau, m) => O.CUT (RS.THM tau, tau) $$ [([],[]) \ O.K (EXTRACT0 tau) $$ [], ([],[]) \ m]
       | VEC_LITERAL (tau, ms) => ret (RS.VEC tau) @@ O.V (VEC_LIT (tau, List.length ms)) $$ List.map (fn m => ([],[]) \ m) ms
       | STR_LITERAL str => ret RS.STR @@ O.V (STR_LIT str) $$ []
       | OPT_SOME (tau, m) => ret (RS.OPT tau) @@ O.V (OP_SOME tau) $$ [([],[]) \ m]
       | OPT_NONE tau => ret (RS.OPT tau) @@ O.V (OP_NONE tau) $$ []

       | TAC_SEQ (t1, us, t2) =>
           let
             val (hyps, sorts) = ListPair.unzip us
           in
             intoTacV (NominalLcfOperators.SEQ sorts) [([],[]) \ t1, (hyps, []) \ t2]
           end
      | TAC_ORELSE (t1, t2) => intoTacV NominalLcfOperators.ORELSE [([],[]) \ t1, ([],[]) \ t2]
      | MTAC_ALL t => intoMTacV NominalLcfOperators.ALL [([],[]) \ t]
      | MTAC_EACH ts => intoMTacV NominalLcfOperators.EACH [([],[]) \ into (VEC_LITERAL (RS.TAC, ts))]
      | MTAC_FOCUS (i, t) => intoMTacV (NominalLcfOperators.FOCUS i) [([],[]) \ t]
      | TAC_PROGRESS t => intoTacV NominalLcfOperators.PROGRESS [([],[]) \ t]
      | TAC_REC (x, tx) => intoTacV NominalLcfOperators.REC [([],[x]) \ tx]
      | TAC_INTRO r => intoTacV (NominalLcfOperators.INTRO r) []
      | TAC_EQ r => intoTacV (NominalLcfOperators.EQ r) []
      | TAC_EXT => intoTacV NominalLcfOperators.EXT []
      | TAC_CUM => intoTacV NominalLcfOperators.CUM []
      | TAC_ELIM (u, tau) => intoTacV (NominalLcfOperators.ELIM (u, tau)) []
      | TAC_UNHIDE (u, tau) => intoTacV (NominalLcfOperators.UNHIDE (u, tau)) []
      | TAC_AUTO => intoTacV NominalLcfOperators.AUTO []
      | TAC_ID => intoTacV NominalLcfOperators.ID []
      | TAC_FAIL => intoTacV NominalLcfOperators.FAIL []
      | TAC_TRACE (tau, m) => intoTacV (NominalLcfOperators.TRACE tau) [([],[]) \ m]
      | TAC_CSTEP n => intoTacV (NominalLcfOperators.CSTEP n) []
      | TAC_CEVAL => intoTacV NominalLcfOperators.CEVAL []
      | TAC_CSYM => intoTacV NominalLcfOperators.CSYM []
      | TAC_REWRITE_GOAL (tau, m) => intoTacV (NominalLcfOperators.REWRITE_GOAL tau) [([],[]) \ m]
      | TAC_EVAL_GOAL u => intoTacV (NominalLcfOperators.EVAL_GOAL u) []
      | TAC_NORMALIZE u => intoTacV (NominalLcfOperators.NORMALIZE u) []
      | TAC_WITNESS (tau, m) => intoTacV (NominalLcfOperators.WITNESS tau) [([],[]) \ m]
      | TAC_UNFOLD (u, v) => intoTacV (NominalLcfOperators.UNFOLD (u, v)) []
      | HYP_REF u => ret RS.EXP @@ O.V (LCF (NominalLcfOperators.HYP_VAR u)) $$ []
      | _ => raise Fail "Stupid SML/NJ says this is non-exhaustive, but doesn't tell me which cases I am missing!"

    local
      fun outVal v =
        case View.out v of
           O.V (CTT_V (CttOperators.CAPPROX tau)) $ [_ \ m, _ \ n] => CAPPROX (tau, m, n)
         | O.V (CTT_V (CttOperators.CEQUIV tau)) $ [_ \ m, _ \ n] => CEQUIV (tau, m, n)
         | O.V (CTT_V (CttOperators.BASE tau)) $ _ => BASE tau
         | O.V (CTT_V (CttOperators.TOP tau)) $ _ => TOP tau
         | O.V (CTT_V (CttOperators.UNIV tau)) $ _ => UNIV tau
         | O.V (CTT_V (CttOperators.MEMBER tau)) $ [_ \ m, _ \ a] => MEMBER (tau, m, a)
         | O.V (CTT_V (CttOperators.EQ tau)) $ [_ \ m, _ \ n, _ \ a] => EQ (tau, m, n, a)
         | O.V (CTT_V CttOperators.AX) $ _ => AX
         | O.V (CTT_V (CttOperators.SQUASH tau)) $ [_ \ a] => SQUASH (tau, a)
         | O.V (CTT_V CttOperators.DFUN) $ [_ \ a, (_, [x]) \ bx] => DFUN (a, x, bx)
         | O.V (CTT_V (CttOperators.ENSEMBLE (sigma, tau))) $ [_ \ a, (_, [x]) \ bx] => ENSEMBLE (sigma, tau, a, x, bx)
         | O.V (CTT_V CttOperators.LAM) $ [(_, [x]) \ mx] => LAM (x, mx)
         | O.V (CTT_V CttOperators.DEP_ISECT) $ [_ \ a, (_, [x]) \ bx] => DEP_ISECT (a, x, bx)
         | O.V (CTT_V CttOperators.VOID) $ _ => VOID

         | O.V (LVL_V 0) $ _ => LBASE
         | O.V (LVL_V n) $ _ => LSUCC @@ ret RS.LVL @@ O.V (LVL_V (n - 1)) $$ []

         | O.V (ATM_V (AtomOperators.ATOM tau)) $ _ => ATOM tau
         | O.V (ATM_V (AtomOperators.TOKEN (u, tau))) $ _ => TOKEN (u, tau)

         | O.V (RCD_V (RecordOperators.CONS u)) $ [_ \ m, _ \ n] => RCD_CONS (u, m, n)
         | O.V (RCD_V (RecordOperators.SINGL u)) $ [_ \ a] =>  RCD_SINGL (u, a)

         | O.V (VEC_LIT (tau, _)) $ es => VEC_LITERAL (tau, List.map (fn _ \ m => m) es)
         | O.V (STR_LIT str) $ _ => STR_LITERAL str
         | O.V (OP_SOME tau) $ [_ \ m] => OPT_SOME (tau, m)
         | O.V (OP_NONE tau) $ _ => OPT_NONE tau
         | O.V (REFINE tau) $ [_ \ m, _ \ s, _ \ e] => REFINE_SCRIPT (tau, m, s, e)

         | O.V (LCF (NominalLcfOperators.SEQ sorts)) $ [_ \ t1, (hyps, _) \ t2] => TAC_SEQ (t1, ListPair.zip (hyps, sorts), t2)
         | O.V (LCF NominalLcfOperators.ORELSE) $ [_ \ t1, _ \ t2] => TAC_ORELSE (t1, t2)
         | O.V (LCF NominalLcfOperators.ALL) $ [_ \ t] => MTAC_ALL t
         | O.V (LCF NominalLcfOperators.EACH) $ [_ \ vec] =>
             (case out vec of
                 VEC_LITERAL (tau, ts) => MTAC_EACH ts
               | _ => raise Fail "Expected vector literal")
         | O.V (LCF (NominalLcfOperators.FOCUS i)) $ [_ \ t] => MTAC_FOCUS (i, t)
         | O.V (LCF NominalLcfOperators.PROGRESS) $ [_ \ t] => TAC_PROGRESS t
         | O.V (LCF NominalLcfOperators.REC) $ [(_, [x]) \ tx] => TAC_REC (x, tx)
         | O.V (LCF (NominalLcfOperators.INTRO r)) $ _ => TAC_INTRO r
         | O.V (LCF (NominalLcfOperators.EQ r)) $ _ => TAC_EQ r
         | O.V (LCF NominalLcfOperators.EXT) $ _ => TAC_EXT
         | O.V (LCF NominalLcfOperators.CUM) $ _ => TAC_CUM
         | O.V (LCF (NominalLcfOperators.ELIM (u, tau))) $ _ => TAC_ELIM (u, tau)
         | O.V (LCF (NominalLcfOperators.HYP (u, tau))) $ _ => TAC_HYP (u, tau)
         | O.V (LCF (NominalLcfOperators.UNHIDE (u, tau))) $ _ => TAC_UNHIDE (u, tau)
         | O.V (LCF NominalLcfOperators.AUTO) $ _ => TAC_AUTO
         | O.V (LCF NominalLcfOperators.ID) $ _ => TAC_ID
         | O.V (LCF NominalLcfOperators.FAIL) $ _ => TAC_FAIL
         | O.V (LCF (NominalLcfOperators.TRACE tau)) $ [_ \ m] => TAC_TRACE (tau, m)
         | O.V (LCF (NominalLcfOperators.CSTEP n)) $ [_ \ m] => TAC_CSTEP n
         | O.V (LCF NominalLcfOperators.CEVAL) $ _ => TAC_CEVAL
         | O.V (LCF NominalLcfOperators.CSYM) $ _ => TAC_CSYM
         | O.V (LCF (NominalLcfOperators.REWRITE_GOAL tau)) $ [_ \ m] => TAC_REWRITE_GOAL (tau, m)
         | O.V (LCF (NominalLcfOperators.EVAL_GOAL u)) $ _ => TAC_EVAL_GOAL u
         | O.V (LCF (NominalLcfOperators.NORMALIZE u)) $ _ => TAC_NORMALIZE u
         | O.V (LCF (NominalLcfOperators.WITNESS tau)) $ [_ \ m] => TAC_WITNESS (tau, m)
         | O.V (LCF (NominalLcfOperators.UNFOLD (u, v))) $ _ => TAC_UNFOLD (u, v)
         | O.V (LCF (NominalLcfOperators.HYP_VAR h)) $ _ => HYP_REF h
         | _ => raise Fail "outVal expected value"

      and outCut k m =
        case View.out k of
           O.K (CTT_K CttOperators.AP) $ [_ \ n] => AP (m, n)
         | O.K (CTT_K CttOperators.DFUN_DOM) $ _ => DFUN_DOM m
         | O.K (CTT_K CttOperators.DFUN_COD) $ [_ \ b] => DFUN_COD (m, b)
         | O.K (CTT_K CttOperators.UNIV_GET_LVL) $ _ => UNIV_GET_LVL m
         | O.K (LVL_K LevelOperators.LSUCC) $ _ => LSUCC m
         | O.K (LVL_K LevelOperators.LSUP0) $ [_ \ n] => LSUP (m, n)
         | O.K (LVL_K (LevelOperators.LSUP1 i)) $ [] => LSUP (m, ret RS.LVL (O.V (LVL_V i) $$ []))
         | O.K (ATM_K (AtomOperators.TEST0 tau)) $ [_ \ t2, _ \ l, _ \ r] => IF_EQ (tau, m, t2, l, r)
         | O.K (ATM_K (AtomOperators.TEST1 ((u, sigma), tau))) $ [_ \ l, _ \ r] => IF_EQ (tau, into (TOKEN (u, sigma)), m, l, r)
         | O.K (RCD_K (RecordOperators.PROJ u)) $ [] => RCD_PROJ (u, m)
         | O.K (RCD_K RecordOperators.SINGL_GET_TY) $ [] => SINGL_GET_TY m
         | O.K (EXTRACT0 tau) $ [_ \ m] => EXTRACT_WITNESS (tau, m)
         | _ => raise Fail "outCut expected continuation"

      and outDef th es =
        case (th, es) of
           (CTT_D CttOperators.FUN, [_ \ a, _ \ b]) => FUN (a, b)
         | (CTT_D CttOperators.NOT, [_ \ a]) => NOT a
         | (RCD_D (RecordOperators.RECORD u), [_ \ a, _ \ b]) => RECORD_TY (u, a, b)
         | _ => raise Fail "outDef expected definitional extension"

     and out m  =
        case View.out m of
           O.RET _ $ [_ \ v] => outVal v
         | O.CUT _ $ [_ \ k, _ \ m] => outCut k m
         | O.D th $ es => outDef th es
         | _ => raise Fail "Syntax view expected application expression"

    in
      val out = out

      fun lvl i =
        O.RET RS.LVL $$ [([],[]) \ O.V (LVL_V i) $$ []]
    end
  end
end

structure RedPrlAbtSyntax = RedPrlSyntax (AbtSyntaxView (RedPrlAbt))
structure RedPrlAstSyntax = RedPrlSyntax (AstSyntaxView (RedPrlAst))
