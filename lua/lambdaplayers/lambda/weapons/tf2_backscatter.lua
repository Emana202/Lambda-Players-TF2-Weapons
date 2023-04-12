local random = math.random
local coroutine_wait = coroutine.wait

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_backscatter = {
        model = "models/lambdaplayers/tf2/weapons/w_scatterdrum.mdl",
        origin = "Team Fortress 2",
        prettyname = "Back Scatter",
        holdtype = "shotgun",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_backscatter",

        clip = 4,
        islethal = true,
        attackrange = 800,
        keepdistance = 200,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "Damage", 4 )
            wepent:SetWeaponAttribute( "RateOfFire", { 0.625, 0.7 } )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_SHOTGUN )
            wepent:SetWeaponAttribute( "Sound", ")weapons/tf2_back_scatter.wav" )
            wepent:SetWeaponAttribute( "CritSound", ")weapons/tf2_back_scatter_crit.wav" )
            wepent:SetWeaponAttribute( "Spread", 0.0675 * 1.20 )
            wepent:SetWeaponAttribute( "ShellEject", false )
            wepent:SetWeaponAttribute( "ProjectileCount", 10 )
            wepent:SetWeaponAttribute( "DamageType", ( DMG_BUCKSHOT + DMG_USEDISTANCEMOD ) )
            wepent:SetWeaponAttribute( "FirstShotAccurate", true )
            wepent:SetWeaponAttribute( "RandomCrits", false )

            wepent:SetWeaponAttribute( "BulletCallback", function( lambda, weapon, tr, dmginfo )
                if LAMBDA_TF2:GetCritType( dmginfo ) != 0 then return end

                local hitEnt = tr.Entity
                if !IsValid( hitEnt ) or !LAMBDA_TF2:IsValidCharacter( hitEnt ) then return end

                local toEnt = ( hitEnt:GetPos() - lambda:GetPos() )
                if toEnt:LengthSqr() >= ( 512 * 512 ) then return end

                toEnt.z = 0; toEnt:Normalize()
                if toEnt:Dot( hitEnt:GetForward() ) <= 0.259 then return end

                dmginfo:SetDamageType( dmginfo:GetDamageType() + DMG_MINICRITICAL )
            end )

            wepent:EmitSound( "weapons/draw_secondary.wav", nil, nil, 0.5 )
        end,

        OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnReload = function( self, wepent )
            LAMBDA_TF2:ShotgunReload( self, wepent, {
                Animation = "reload_smg1_alt",
                StartDelay = 0.7,
                CycleSound = "weapons/scatter_gun_worldreload.wav",
                CycleFunction = function( lambda, weapon )
                    LAMBDA_TF2:CreateShellEject( weapon, "ShotgunShellEject" )
                end,
                EndFunction = false
            } )

            return true
        end
    }
} )