<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.8" tiledversion="1.8.2" name="misc" tilewidth="64" tileheight="64" tilecount="4" columns="0">
 <grid orientation="orthogonal" width="1" height="1"/>
 <tile id="1">
  <image width="32" height="32" source="../textures/slime/slime_idle_1.png"/>
 </tile>
 <tile id="2">
  <image width="64" height="64" source="../textures/spectre/spectre_idle_1.png"/>
 </tile>
 <tile id="3">
  <properties>
   <property name="active" type="bool" value="false"/>
  </properties>
  <image width="16" height="16" source="../textures/misc/checkpoint.png"/>
 </tile>
 <tile id="4">
  <properties>
   <property name="active" type="bool" value="true"/>
  </properties>
  <image width="16" height="16" source="../textures/misc/checkpoint_active.png"/>
 </tile>
</tileset>
