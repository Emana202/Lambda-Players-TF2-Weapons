table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_backburner = {
        model = "models/lambdaplayers/tf2/weapons/w_flamethrower.mdl",
        origin = "Team Fortress 2",
        prettyname = "Backburner",
        holdtype = "shotgun",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_backburner",

        clip = 200,
        islethal = true,
        attackrange = 350,
        keepdistance = 250,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 100 )
            wepent:SetWeaponAttribute( "RateOfFire", 0.04 )
            wepent:SetWeaponAttribute( "UseRapidFireCrits", true )
            wepent:SetWeaponAttribute( "DamageType", DMG_PREVENT_PHYSICS_FORCE )
            wepent:SetWeaponAttribute( "RandomCrits", false )
            wepent:SetWeaponAttribute( "DamageCustom", ( TF_DMG_CUSTOM_IGNITE + TF_DMG_CUSTOM_BURNING ) )

            wepent:SetWeaponAttribute( "StartFireSound", ")weapons/flame_thrower_bb_start.wav" )
            wepent:SetWeaponAttribute( "FireSound", ")weapons/flame_thrower_bb_loop.wav" )
            wepent:SetWeaponAttribute( "CritFireSound", ")weapons/flame_thrower_bb_loop_crit.wav" )
            wepent:SetWeaponAttribute( "EndFireSound", ")weapons/flame_thrower_bb_end.wav" )

            wepent:SetWeaponAttribute( "OnFlameCollide", function( flame, ent, dmginfo )
                local dmgCustom = dmginfo:GetDamageCustom()
                if LAMBDA_TF2:IsDamageCustom( dmgCustom, TF_DMG_CUSTOM_CRITICAL ) then return end

                local entForward = ent:GetForward()
                entForward.z = 0; entForward:Normalize()

                local travelVel = flame.l_BaseVelocity
                travelVel.z = 0; travelVel:Normalize()

                if entForward:Dot( travelVel ) > 0.8 then
                    dmginfo:SetDamageCustom( dmgCustom - TF_DMG_CUSTOM_BURNING + TF_DMG_CUSTOM_CRITICAL + TF_DMG_CUSTOM_BURNING_BEHIND )
                end
            end )
            
            LAMBDA_TF2:FlamethrowerDeploy( self, wepent )
            wepent:SetBodygroup( 1, 1 )
        end,
        
        OnDrop = function( self, wepent, cs_prop )
            cs_prop:SetBodygroup( 1, wepent:GetBodygroup( 1 ) )
        end,

        OnThink = function( self, wepent, isdead )
            LAMBDA_TF2:FlamethrowerThink( self, wepent, isdead )
        end,

        OnHolster = function( self, wepent )
            LAMBDA_TF2:FlamethrowerHolster( self, wepent )
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:FlamethrowerFire( self, wepent, target )
            return true
        end
    }
} )