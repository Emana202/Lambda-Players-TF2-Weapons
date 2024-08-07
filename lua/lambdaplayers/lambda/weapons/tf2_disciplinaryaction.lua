local ignorePlys = GetConVar( "ai_ignoreplayers" )

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_disciplinaryaction = {
        model = "models/lambdaplayers/tf2/weapons/w_riding_crop.mdl",
        origin = "Team Fortress 2",
        prettyname = "Disciplinary Action",
        holdtype = "melee",
        bonemerge = true,
        tfclass = 2,

        killicon = "lambdaplayers/killicons/icon_tf2_disciplinaryaction",
        keepdistance = 10,
        attackrange = 75,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "Sound", {
                ")weapons/discipline_device_woosh_01.wav",
                ")weapons/discipline_device_woosh_02.wav"
            } )
            wepent:SetWeaponAttribute( "HitSound", {
                ")weapons/discipline_device_impact_01.wav",
                ")weapons/discipline_device_impact_02.wav"
            } )
            wepent:SetWeaponAttribute( "HitCritSound", {
                ")weapons/discipline_device_impact_crit_01.wav",
                ")weapons/discipline_device_impact_crit_02.wav"
            } )
            wepent:SetWeaponAttribute( "Damage", 30 )
            wepent:SetWeaponAttribute( "HitRange", 71.4 )

            wepent:SetWeaponAttribute( "PreHitCallback", function( lambda, weapon, target )
                local isSpeedBuff = weapon.l_IsSpeedBuffAttack
                weapon.l_IsSpeedBuffAttack = false

                if isSpeedBuff then
                    target:EmitSound( ")weapons/discipline_device_impact_0" .. LambdaRNG( 2 ) .. ".wav", nil, nil, nil, CHAN_STATIC )
                    
                    if !target.l_TF_InSpeedBoost then target:EmitSound( ")weapons/discipline_device_power_up.wav", 65, nil, nil, CHAN_STATIC ) end
                    target.l_TF_InSpeedBoost = ( CurTime() + 2 )
                    lambda.l_TF_InSpeedBoost = ( CurTime() + 3.6 )

                    lambda:SetRun( true )
                    if target.IsLambdaPlayer then target:SetRun( true ) end

                    return true
                end
            end )
            wepent:SetWeaponAttribute( "OnMiss", function( lambda, weapon )
                weapon.l_IsSpeedBuffAttack = false
            end )

            wepent.l_IsSpeedBuffAttack = false
            wepent:EmitSound( "weapons/draw_shovel_soldier.wav" )
        end,

        OnThink = function( self, wepent )
            local ene = self:GetEnemy()
            if !self:InCombat() or !self:IsInRange( ene, 300 ) then
                local retTarg = self.l_RetreatTarget

                local nearTargets = self:FindInSphere( self:GetAttachmentPoint( "eyes" ).Pos, wepent:GetWeaponAttribute( "HitRange" ), function( ent )
                    if self:InCombat() and ent == ene then return false end
                    if self:IsPanicking() and ent == retTarg then return false end
                    if ent.IsLambdaPlayer and ent:InCombat() and ent:GetEnemy() == self then return false end
                    if ent:IsPlayer() and ignorePlys:GetBool() then return false end
                    return ( LAMBDA_TF2:IsValidCharacter( ent ) and ( LambdaRNG( 3 ) == 1 and self:CanTarget( ent ) or self.IsFriendsWith and self:IsFriendsWith( ent ) or LambdaTeams and LambdaTeams:AreTeammates( self, ent ) == true ) and self:CanSee( ent ) )
                end )

                if #nearTargets > 0 then
                    wepent.l_IsSpeedBuffAttack = true
                    local rndTarget = nearTargets[ LambdaRNG( #nearTargets ) ]
                    self:LookTo( rndTarget, 0.66 )
                    self:UseWeapon( rndTarget )
                end
            end

            return 1.0
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnDealDamage = false
    }
} )