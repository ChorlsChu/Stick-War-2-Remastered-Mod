package com.brockw.stickwar.engine
{
   import com.brockw.stickwar.engine.units.Wall;
   import flash.utils.Dictionary;
   
   public class SpatialHash
   {
      
      private var partitions:Vector.<Vector.<Entity>>;
      
      private var partitionSizes:Vector.<int>;
      
      private var width:Number;
      
      private var height:Number;
      
      private var boxWidth:Number;
      
      private var boxHeight:Number;
      
      private var cols:int;
      
      private var rows:int;
      
      internal var visited:Dictionary;
      
      private var visitToken:int;
      
      internal var game:StickWar;
      
      public function SpatialHash(game:StickWar, width:Number, height:Number, boxWidth:Number, boxHeight:Number, maxEntitys:int)
      {
         var x:int = 0;
         super();
         this.game = game;
         this.partitions = new Vector.<Vector.<Entity>>(width / boxWidth * height / boxHeight,false);
         this.partitionSizes = new Vector.<int>(width / boxWidth * height / boxHeight,false);
         this.visited = new Dictionary();
         this.visitToken = 1;
         this.width = width;
         this.height = height;
         this.boxWidth = boxWidth;
         this.boxHeight = boxHeight;
         this.rows = height / boxHeight;
         this.cols = width / boxWidth;
         var y:int = 0;
         while(y < this.rows)
         {
            x = 0;
            while(x < this.cols)
            {
               this.partitions[this.cols * y + x] = new Vector.<Entity>(maxEntitys,false);
               this.partitionSizes[this.cols * y + x] = 0;
               x++;
            }
            y++;
         }
      }
      
      public function cleanUp() : void
      {
         var x:int = 0;
         var i:int = 0;
         var y:int = 0;
         while(y < this.rows)
         {
            x = 0;
            while(x < this.cols)
            {
               i = 0;
               while(i < this.partitions[this.cols * y + x].length)
               {
                  this.partitions[this.cols * y + x][i] = null;
                  i++;
               }
               this.partitions[this.cols * y + x] = null;
               x++;
            }
            y++;
         }
         this.partitions = null;
         this.partitionSizes = null;
      }
      
      public function add(entity:Entity) : void
      {
         var x:int = entity.px / this.boxWidth;
         var y:int = entity.py / this.boxHeight;
         if(x < 0 || x >= this.cols || y < 0 || y >= this.rows)
         {
            return;
         }
         Vector.<Entity>(this.partitions[this.cols * y + x])[this.partitionSizes[this.cols * y + x]] = entity;
         ++this.partitionSizes[this.cols * y + x];
         if(x > 0)
         {
            Vector.<Entity>(this.partitions[this.cols * y + x - 1])[this.partitionSizes[this.cols * y + x - 1]] = entity;
            ++this.partitionSizes[this.cols * y + x - 1];
         }
         if(y > 0)
         {
            Vector.<Entity>(this.partitions[this.cols * (y - 1) + x])[this.partitionSizes[this.cols * (y - 1) + x]] = entity;
            ++this.partitionSizes[this.cols * (y - 1) + x];
         }
         if(y < this.rows - 1)
         {
            Vector.<Entity>(this.partitions[this.cols * (y + 1) + x])[this.partitionSizes[this.cols * (y + 1) + x]] = entity;
            ++this.partitionSizes[this.cols * (y + 1) + x];
         }
         if(x < this.cols - 1)
         {
            Vector.<Entity>(this.partitions[this.cols * y + x + 1])[this.partitionSizes[this.cols * y + x + 1]] = entity;
            ++this.partitionSizes[this.cols * y + x + 1];
         }
      }
      
      public function mapInArea(xs:Number, ys:Number, xe:Number, ye:Number, f:Function, includeWalls:Boolean = true) : void
      {
         var wall:Wall = null;
         var y:int = 0;
         var i:int = 0;
         var x:int = 0;
         var cellIndex:int = 0;
         var entity:Entity = null;
         var startX:int = 0;
         var startY:int = 0;
         var endX:int = 0;
         var endY:int = 0;
         var lower:Number = Math.min(xs,xe);
         var upper:Number = Math.max(xs,xe);
         if(includeWalls)
         {
            for each(wall in this.game.teamA.walls)
            {
               if(wall.px > lower && wall.px < upper)
               {
                  f(wall);
               }
            }
            for each(wall in this.game.teamB.walls)
            {
               if(wall.px > lower && wall.px < upper)
               {
                  f(wall);
               }
            }
         }
         startX = int(xs / this.boxWidth);
         startY = int(ys / this.boxHeight);
         endX = Math.ceil(xe / this.boxWidth) - 1;
         endY = Math.ceil(ye / this.boxHeight) - 1;
         ++this.visitToken;
         if(this.visitToken == 0)
         {
            this.visitToken = 1;
            this.visited = new Dictionary();
         }
         x = startX;
         while(x <= endX)
         {
            y = startY;
            while(y <= endY)
            {
               cellIndex = this.cols * y + x;
               if(!(cellIndex < 0 || cellIndex >= this.partitions.length))
               {
                  i = 0;
                  while(i < this.partitionSizes[cellIndex])
                  {
                     entity = this.partitions[cellIndex][i];
                     if(this.visited[entity.id] !== this.visitToken)
                     {
                        f(entity);
                        this.visited[entity.id] = this.visitToken;
                     }
                     i++;
                  }
               }
               y++;
            }
            x++;
         }
      }
      
      public function getNearbyEntitys(entity:Entity) : Vector.<Entity>
      {
         var x:int = entity.px / this.boxWidth;
         var y:int = entity.py / this.boxHeight;
         if(this.cols * y + x < 0 || this.cols * y + x >= this.partitions.length)
         {
            return new Vector.<Entity>();
         }
         return this.partitions[this.cols * y + x];
      }
      
      public function getNearbyEntitysXY(x:Number, y:Number) : Vector.<Entity>
      {
         x = Math.floor(x / this.boxWidth);
         y = Math.floor(y / this.boxHeight);
         if(this.cols * y + x < 0 || this.cols * y + x >= this.partitions.length)
         {
            return new Vector.<Entity>();
         }
         return this.partitions[this.cols * y + x];
      }
      
      public function getNumberOfNearbyEntitysXY(x:Number, y:Number) : int
      {
         x = Math.floor(x / this.boxWidth);
         y = Math.floor(y / this.boxHeight);
         if(this.cols * y + x < 0 || this.cols * y + x >= this.partitions.length)
         {
            return 0;
         }
         return this.partitionSizes[this.cols * y + x];
      }
      
      public function getNumberOfNearbyEntitys(entity:Entity) : int
      {
         var x:int = entity.px / this.boxWidth;
         var y:int = entity.py / this.boxHeight;
         if(this.cols * y + x < 0 || this.cols * y + x >= this.partitions.length)
         {
            return 0;
         }
         return this.partitionSizes[this.cols * y + x];
      }
      
      public function clear() : void
      {
         var x:int = 0;
         var y:int = 0;
         while(y < this.rows)
         {
            x = 0;
            while(x < this.cols)
            {
               this.partitionSizes[this.cols * y + x] = 0;
               x++;
            }
            y++;
         }
      }
   }
}

