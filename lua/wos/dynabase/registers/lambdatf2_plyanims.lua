local registerTbl = {
	Name = "[LambdaPlayers] TF2 Player Animations",
	Type =  WOS_DYNABASE.EXTENSION,
	Male = "models/xdreanims/m_anm_slot_034.mdl",
	Female = "models/xdreanims/f_anm_slot_034.mdl",
	Zombie = "models/xdreanims/m_anm_slot_034.mdl"
}

wOS.DynaBase:RegisterSource( registerTbl )

hook.Add( "PreLoadAnimations", "DynaBaseRegister_TF2Anims", function( gender )
	if gender == WOS_DYNABASE.MALE or gender == WOS_DYNABASE.ZOMBIE then
		IncludeModel( "models/xdreanims/m_anm_slot_034.mdl" )
	elseif gender == WOS_DYNABASE.FEMALE then
		IncludeModel( "models/xdreanims/f_anm_slot_034.mdl" )
	end
end )

hook.Add( "InitLoadAnimations", "DynaBaseLoad_TF2Anims", function()
	wOS.DynaBase:RegisterSource( registerTbl )
end )