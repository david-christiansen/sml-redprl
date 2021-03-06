signature PI_RULES =
sig
  val IsType : RefinerKit.ntactic
  val TypeEq : RefinerKit.ntactic
  val MemberEq : RefinerKit.ntactic
  val ApSynth : RefinerKit.ntactic

  val Intro : RefinerKit.ntactic
  val Elim : RefinerKit.symbol -> RefinerKit.ntactic
  val Ext : RefinerKit.ntactic
end
