namespace DOL.AI.Brain
{
    public class GuardState_RETURN_TO_SPAWN : StandardMobState_RETURN_TO_SPAWN
    {
        // True 1.65 Mode: the traveler's inn guards walk back to their posts (owner 2026-10-30: no running around the inns)
        protected override short Speed => DOL.GS.Classic165Mode.IsOn && _brain.Body.PackageID == "true165_inn"
            ? DOL.GS.NpcMovementComponent.DEFAULT_WALK_SPEED : _brain.Body.MaxSpeed;

        public GuardState_RETURN_TO_SPAWN(StandardMobBrain brain) : base(brain) { }
    }
}
