# BlendShape Shader

[![Head Pats!](https://i.imgur.com/VkcVsUc.png)](https://my.mixtape.moe/zvsdgx.mp4)

[![Feet Squish!](https://i.imgur.com/ewIEwOJ.png)](https://my.mixtape.moe/hrqqeu.mp4)

It's simple! It detects intersections, then activates a blendshape.

If you want to help support this kind of development, feel free to support me through google wallet (naelstrof@gmail.com) or through my [Digital Tip Jar](https://digitaltipjar.com/naelstrof)!

## Usage

1. Install the unity package from the Releases Tab above.
2. Apply any of the BlendShape variants to your model.
3. Run the GameObject->Bake Blend Shapes wizard on the affected mesh.
4. Adjust the shader parameters until it looks good!
5. Add a low intensity (0.01), shadow-casting (hard-shadows are cheaper), masked (to an unused layer), directional light to the character. (This force-enables the depth buffer).
6. Done!

## Detailed Usage

Install the unity package by clicking on `Assets->Import Package->Import Custom Package` in the top bar.

Open your model in blender, then add a new shape key.

![Blender](https://i.imgur.com/eFNnRck.png)

Edit the shape key to taste. For each vertex, imagine what should happen when it gets touched. Feet and hands will typically spread/squish, while hair might ruffle.

![Blender Feet Squish Creation](https://i.imgur.com/UINEG1d.png)
![Blender Head Pat Creation](https://i.imgur.com/jRusKkb.png)

Export it into Unity, then switch the shader to a Naelstrof/BlendShape variant.

![Unity Shader Selection](https://i.imgur.com/lpbbkMs.png)

This will cause your model to explode! This is normal. 🎉
Click on GameObject->Bake Blend Shapes.

![Unity Dropdown Selection](https://i.imgur.com/OnWA1e7.png)

Fill out the wizard information, ensure `Pack norm/tang deltas` is checked!

![Unity Wizard](https://i.imgur.com/j28v8l2.png)

Adjust the shader settings until things look right! The defaults are probably not going to look good or do what you want due to me being bad at math. Luckily they're adjustable.

![Shader adjustments]( https://i.imgur.com/eDDNoEW.png)

Make sure extraneous objects are set to a Late render variant, to keep them from triggering the blendshapes.

![Unity Shader Selection 2](https://i.imgur.com/PxBJT8n.png)

Finally we need to make sure the Depth Buffer is available, in VRChat the only current possible way to ensure this is to create a low intensity directional light.

First we need to create a new layer that will have a very low likelyhood of being used. It doesn't matter what it's named.

![Unity Layer Adding](https://i.imgur.com/NmOWsTU.png)

In the final layer, add a name like "unused".

![Unity Layer Adding 2](https://i.imgur.com/cWQmH9c.png)

Now we can add a new directional light to the character, then set its settings to not hurt anyone performance wise! Copy the settings as displayed here.

![Unity Set Directional Light Parameters](https://i.imgur.com/SAernjY.png)

Done! Your avatar should be working now!
