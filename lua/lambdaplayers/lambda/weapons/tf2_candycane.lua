local ceil = math.ceil

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_candycane = {
        model = "models/lambdaplayers/tf2/weapons/w_candy_cane.mdl",
        origin = "Team Fortress 2",
        prettyname = "Candy Cane",
        holdtype = "melee",
        bonemerge = true,

        killicon = "lambdaplayers/killicons/icon_tf2_candy_cane",
        keepdistance = 10,
        attackrange = 45,        
		islethal = true,
        ismelee = true,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "IsMelee", true )
            wepent:SetWeaponAttribute( "Damage", 20 )
            wepent:SetWeaponAttribute( "RateOfFire", 0.5 )
            wepent:SetWeaponAttribute( "HitSound", ")weapons/bat_hit.wav" )

            wepent:EmitSound( "weapons/bat_draw.wav", nil, nil, 0.5 )
            self:SimpleWeaponTimer( 0.266667, function() wepent:EmitSound( "weapons/bat_draw_swoosh1.wav", nil, nil, 0.45, CHAN_STATIC ) end )
            self:SimpleWeaponTimer( 0.533333, function() wepent:EmitSound( "weapons/bat_draw_swoosh2.wav", nil, nil, 0.45, CHAN_STATIC ) end )
            self:SimpleWeaponTimer( 0.666667, function() wepent:EmitSound( "weapons/metal_hit_hand1.wav", nil, nil, nil, CHAN_WEAPON ) end )
        end,
        
		OnAttack = function( self, wepent, target )
            LAMBDA_TF2:WeaponAttack( self, wepent, target )
            return true 
        end,

        OnDealDamage = function( self, wepent, target, dmginfo, tookDamage, isLethal )
            if !isLethal then return end

            local medkit = ents.Create( "base_anim" )
            medkit:SetModel( "models/items/medkit_small.mdl" )
            medkit:SetPos( target:WorldSpaceCenter() )
            medkit:SetOwner( target )

            medkit.AutomaticFrameAdvance = true
            medkit.l_IsTFMedkit = true
            medkit:Spawn()
            medkit:PhysicsDestroy()
            medkit:SetSolidFlags( FSOLID_NOT_SOLID + FSOLID_TRIGGER )
            medkit:ResetSequence( medkit:LookupSequence( "idle" ) )
            SafeRemoveEntityDelayed( medkit, 30 )

            medkit:SetMoveType( MOVETYPE_FLYGRAVITY )
            medkit:SetMoveCollide( MOVECOLLIDE_FLY_BOUNCE )
            medkit:SetSolid( SOLID_BBOX )

            local rndImpulse = VectorRand( -1, 1 )
            rndImpulse.z = 1; rndImpulse:Normalize()
            local velocity = ( rndImpulse * 250 )
            medkit:SetAbsVelocity( velocity )

            function medkit:Think()
                medkit:NextThink( CurTime() )
                return true
            end

            function medkit:Touch( other )
                if !IsValid( other ) or !LAMBDA_TF2:IsValidCharacter( other ) then return end
                local givenHealth = LAMBDA_TF2:GiveHealth( other, ceil( other:GetMaxHealth() * 0.2 ), false )

                if givenHealth > 0 or LAMBDA_TF2:IsBleeding( other ) or LAMBDA_TF2:IsBurning( other ) then
                    medkit:EmitSound( "HealthKit.Touch" )
                    LAMBDA_TF2:RemoveBurn( other )
                    LAMBDA_TF2:RemoveBleeding( other )
                    medkit:Remove()
                end
            end
        end,

        OnTakeDamage = function( self, wepent, dmginfo )
            if !dmginfo:IsExplosionDamage() then return end
            dmginfo:ScaleDamage( 1.25 )
        end
    }
} )