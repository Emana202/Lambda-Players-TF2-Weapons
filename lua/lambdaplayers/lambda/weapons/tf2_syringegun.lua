local CurTime = CurTime
local random = math.random
local Rand = math.Rand
local SafeRemoveEntityDelayed = SafeRemoveEntityDelayed
local ents_Create = ents.Create
local net = net
local SpriteTrail = util.SpriteTrail
local SimpleTimer = timer.Simple
local bulletTbl = {
    Tracer = 0,
    Spread = vector_zero
}

local function OnSyringeTouch( self, ent )
    if !ent or !ent:IsSolid() or ent:GetSolidFlags() == FSOLID_VOLUME_CONTENTS then return end

    if ent.l_IsTF2Syringe then
        self:SetPos( self:GetPos() + self:GetVelocity() * FrameTime() * 2 )
        return 
    end

    local owner = self:GetOwner()
    if !IsValid( owner ) then self:Remove() return end

    local wepent = owner.WeaponEnt
    if !IsValid( wepent ) then self:Remove() return end

    bulletTbl.Attacker = owner
    bulletTbl.IgnoreEntity = self
    bulletTbl.Src = self:GetPos()
    bulletTbl.Dir = ( ( self:GetPos() + self:GetVelocity() ) - self:GetPos() ):GetNormalized()

    local damage = self.l_HitDamage
    bulletTbl.Damage = damage
    bulletTbl.Force = damage

    bulletTbl.Callback = function( attacker, tr, dmginfo )
        self.l_Stopped = true
        self:SetSolid( SOLID_NONE )
        self:SetMoveType( MOVETYPE_NONE )
        self:SetVelocity( vector_origin )
        self:SetPos( tr.HitPos )
        if self.l_IsCritical then dmginfo:SetDamageType( dmginfo:GetDamageType() + DMG_CRITICAL ) end

        if tr.HitWorld then
            SafeRemoveEntityDelayed( self, 10 )
            SafeRemoveEntityDelayed( self.CritTrail, 1 )
        else
            self:Remove()
        end
    end

    wepent:FireBullets( bulletTbl )
end

local function OnSyringeThink( self )
    if self.l_Stopped then return end
    local selfPos = self:GetPos()
    self:SetAngles( ( ( selfPos + self:GetVelocity() ) - selfPos ):Angle() )
end

table.Merge( _LAMBDAPLAYERSWEAPONS, {
    tf2_syringegun = {
        model = "models/lambdaplayers/weapons/tf2/w_syringegun.mdl",
        origin = "Team Fortress 2",
        prettyname = "Syringe Gun",
        holdtype = "ar2",
        bonemerge = true,
        killicon = "lambdaplayers/killicons/icon_tf2_syringegun",

        clip = 40,
        islethal = true,
        attackrange = 2000,
        keepdistance = 500,
        deploydelay = 0.5,

        OnDeploy = function( self, wepent )
            LAMBDA_TF2:InitializeWeaponData( self, wepent )

            wepent:SetWeaponAttribute( "FireBullet", false )
            wepent:SetWeaponAttribute( "Damage", 6 )
            wepent:SetWeaponAttribute( "RateOfFire", 0.105 )
            wepent:SetWeaponAttribute( "Animation", ACT_HL2MP_GESTURE_RANGE_ATTACK_SMG1 )
            wepent:SetWeaponAttribute( "Sound", "lambdaplayers/weapons/tf2/syringegun/syringegun_shoot.mp3" )
            wepent:SetWeaponAttribute( "MuzzleFlash", false )
            wepent:SetWeaponAttribute( "ShellEject", false )
            wepent:SetWeaponAttribute( "IsRapidFire", true )

            wepent:SetSkin( random( 0, 1 ) )
            wepent:EmitSound( "lambdaplayers/weapons/tf2/draw_secondary.mp3", 60 )
        end,

        OnAttack = function( self, wepent, target )
            local spawnPos = wepent:GetAttachment( wepent:LookupAttachment( "muzzle" ) ).Pos
            local targetPos = ( target:WorldSpaceCenter() + ( ( target:IsNextBot() and target.loco or target ):GetVelocity() * ( ( self:GetRangeTo( target ) * Rand( 0.5, 0.9 ) ) / 990 ) ) + vector_up * ( self:GetRangeTo( target ) / random( 7.5, 12.5 ) ) )
            local spawnAng = ( targetPos - spawnPos ):Angle()

            spawnAng = ( ( targetPos + spawnAng:Right() * random( -5, 5 ) + spawnAng:Up() * random( -5, 5 ) ) - spawnPos ):Angle()
            spawnPos = ( spawnPos + spawnAng:Forward() * ( self.loco:GetVelocity():Length() * FrameTime() ) )
            if self:GetForward():Dot( spawnAng:Forward() ) <= 0.5 then self.l_WeaponUseCooldown = ( CurTime() + 0.1 ) return true end

            if !LAMBDA_TF2:WeaponAttack( self, wepent, target ) then return true end

            local syringe = ents_Create( "base_anim" )
            if !IsValid( syringe ) then return true end

            syringe:SetPos( spawnPos )
            syringe:SetAngles( spawnAng )
            syringe:SetModel( "models/lambdaplayers/weapons/tf2/w_syringegun_proj.mdl" )
            syringe:SetOwner( self )
            syringe:Spawn()

            syringe:SetGravity( 0.3 )
            syringe:DrawShadow( false )
            syringe:SetSolid( SOLID_BBOX )
            syringe:SetMoveType( MOVETYPE_FLYGRAVITY )
            syringe:SetVelocity( spawnAng:Forward() * 990 )

            local plyColor = self:GetPlyColor()
            net.Start( "lambdaplayers_serversideragdollplycolor" )
                net.WriteEntity( syringe )
                net.WriteVector( plyColor )
            net.Broadcast()

            syringe.l_IsTF2Syringe = true
            syringe.l_Stopped = false
            syringe.l_HitDamage = wepent:GetWeaponAttribute( "Damage" )
            syringe.l_IsCritical = false
            
            syringe.Touch = OnSyringeTouch
            syringe.Think = OnSyringeThink

            local isCrit = wepent:CalcIsAttackCriticalHelper()
            if isCrit then
                wepent:EmitSound( "lambdaplayers/weapons/tf2/crits/crit_shoot.mp3", 75, random( 90, 110 ), 1, CHAN_STATIC )
                syringe.l_IsCritical = true
                syringe:SetMaterial( "models/shiny" )
                syringe:SetColor( plyColor:ToColor() )
                syringe.CritTrail = SpriteTrail( syringe, 0, plyColor:ToColor(), true, 3, 1.5, 0.5, ( 1 / ( 3 + 1.5 ) * 0.5 ), "trails/laser" )
            end

            return true
        end,

        reloadtime = 1.305,
        reloadsounds = { { 0, "lambdaplayers/weapons/tf2/syringegun/syringegun_worldreload.mp3" } },

        OnReload = function( self, wepent )
            self:RemoveGesture( ACT_HL2MP_GESTURE_RELOAD_SMG1 )
            local reloadLayer = self:AddGestureSequence( self:LookupSequence( "reload_smg1_alt" ) )
            self:SetLayerPlaybackRate( reloadLayer, 1.25 )
        end
    }
} )