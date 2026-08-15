package com.brockw.stickwar.campaign.controllers
{
   import com.brockw.stickwar.GameScreen;
   import com.brockw.stickwar.engine.Ai.command.*;
   import com.brockw.stickwar.engine.Team.Tech;
   import com.brockw.stickwar.engine.units.Bomber;
   import com.brockw.stickwar.engine.units.Unit;
   
   public class CampaignBomber extends CampaignController
   {
      
      private static const MIN_NUM_BOMBERS:int = 2;
      
      public static const MAX_NUM_BOMBERS:int = 10;
      
      private static const FREQUENCY_SPAWN:int = 45;
      
      private static const FREQUENCY_INCREASE:int = 60;
      
      private static const ATTACK_REFRESH_FRAMES:int = 60;
      
      private static const FORMATION_LANE_OFFSET:Number = 70;
      
      private var numToSpawn:int = 0;
      
      private var hasAppliedGiantGrowth:Boolean;
      
      private var lastBomberCount:int = 0;
      
      private var pendingAttackRefreshes:Array = [];
      
      public function CampaignBomber(gameScreen:GameScreen)
      {
         super(gameScreen);
         this.numToSpawn = MIN_NUM_BOMBERS;
         this.hasAppliedGiantGrowth = false;
      }
      
      override public function update(gameScreen:GameScreen) : void
      {
         var i:int = 0;
         var u1:Unit = null;
         if(!this.hasAppliedGiantGrowth)
         {
            gameScreen.game.team.enemyTeam.tech.isResearchedMap[Tech.GIANT_GROWTH_I] = true;
            gameScreen.game.team.enemyTeam.tech.isResearchedMap[Tech.GIANT_GROWTH_II] = true;
            this.hasAppliedGiantGrowth = true;
         }
         this.updatePendingAttackRefreshes(gameScreen);
         if(gameScreen.game.frame % (30 * FREQUENCY_SPAWN) == 0)
         {
            for(i = 0; i < this.numToSpawn; i++)
            {
               u1 = Bomber(gameScreen.game.unitFactory.getUnit(Unit.U_BOMBER));
               gameScreen.team.enemyTeam.spawn(u1,gameScreen.game);
               u1.px = gameScreen.team.enemyTeam.statue.x;
               u1.py = gameScreen.game.map.height / 2;
               this.makeIndependentAttacker(gameScreen,u1);
               gameScreen.team.enemyTeam.population += 1;
            }
            this.scheduleAttackRefresh(gameScreen);
         }
         if(gameScreen.game.frame % (30 * FREQUENCY_INCREASE) == 0)
         {
            ++this.numToSpawn;
            if(this.numToSpawn > MAX_NUM_BOMBERS)
            {
               this.numToSpawn = MAX_NUM_BOMBERS;
            }
         }
         this.updateBomberFormation(gameScreen);
         this.convertNewAttackers(gameScreen);
      }
      
      private function convertNewAttackers(gameScreen:GameScreen) : void
      {
         var unit:Unit = null;
         for each(unit in gameScreen.team.enemyTeam.unitGroups[Unit.U_GIANT])
         {
            if(unit != null && unit.isAlive() && !unit.isBossMovementLocked)
            {
               this.makeIndependentAttacker(gameScreen,unit);
            }
         }
      }
      
      private function updateBomberFormation(gameScreen:GameScreen, forceRefresh:Boolean = false) : void
      {
         var unit:Unit = null;
         var bombers:Array = [];
         var i:int = 0;
         var count:int = 0;
         for each(unit in gameScreen.team.enemyTeam.unitGroups[Unit.U_BOMBER])
         {
            if(unit != null && unit.isAlive())
            {
               bombers.push(unit);
            }
         }
         count = bombers.length;
         if(!forceRefresh)
         {
            if(count <= this.lastBomberCount)
            {
               this.lastBomberCount = count;
               return;
            }
         }
         if(count == 0)
         {
            this.lastBomberCount = count;
            return;
         }
         for(i = 0; i < count; i++)
         {
            unit = bombers[i];
            if(unit.ai == null)
            {
               continue;
            }
            unit.isBossMovementLocked = true;
            unit.ai.mayAttack = true;
            unit.ai.mayMoveToAttack = true;
            this.issueForwardAttackCommand(gameScreen,unit,i,count);
         }
         this.lastBomberCount = count;
      }
      
      private function makeIndependentAttacker(gameScreen:GameScreen, unit:Unit) : void
      {
         if(unit == null || unit.ai == null)
         {
            return;
         }
         unit.isBossMovementLocked = true;
         unit.ai.mayAttack = true;
         unit.ai.mayMoveToAttack = true;
         this.issueForwardAttackCommand(gameScreen,unit);
      }
      
      private function scheduleAttackRefresh(gameScreen:GameScreen) : void
      {
         this.pendingAttackRefreshes.push(gameScreen.game.frame + ATTACK_REFRESH_FRAMES);
      }
      
      private function updatePendingAttackRefreshes(gameScreen:GameScreen) : void
      {
         var i:int = 0;
         while(i < this.pendingAttackRefreshes.length)
         {
            if(gameScreen.game.frame < int(this.pendingAttackRefreshes[i]))
            {
               i++;
            }
            else
            {
               this.updateBomberFormation(gameScreen,true);
               this.pendingAttackRefreshes.splice(i,1);
            }
         }
      }
      
      private function issueForwardAttackCommand(gameScreen:GameScreen, unit:Unit, laneIndex:int = 0, laneCount:int = 1) : void
      {
         var attackMoveCommand:AttackMoveCommand = new AttackMoveCommand(gameScreen.game);
         var laneOffset:Number = 0;
         attackMoveCommand.type = UnitCommand.ATTACK_MOVE;
         if(laneCount > 1)
         {
            laneOffset = (laneIndex - (laneCount - 1) / 2) * FORMATION_LANE_OFFSET;
         }
         attackMoveCommand.goalX = gameScreen.team.statue.px;
         attackMoveCommand.goalY = gameScreen.game.map.height / 2 + laneOffset;
         attackMoveCommand.realX = gameScreen.team.statue.px;
         attackMoveCommand.realY = attackMoveCommand.goalY;
         unit.ai.setCommand(gameScreen.game,attackMoveCommand);
      }
   }
}
