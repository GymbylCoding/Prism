### Prism

Prism is a new particle effects engine for Corona SDK. It's a single file, very simple and straightforward to use, and quite fast in the bargain.

#### What About CBE?

Don't worry, I'm not discontinuing support for CBE. The thing is, CBE is very stable, which means I don't have to constantly be working on it. This is not an engine to push CBE out of the way or make CBE obsolete. Instead, Prism is simply an alternative; it's an engine created based on my experience with CBE. There are some things in CBE that I'd change if I had to rewrite it, and some decisions in CBE I made (hopefully for the better) that I'm curious about what would have happened on the other hand. That's what Prism is - the engine CBE would have been in an alternate universe.

#### Why a New Particle System?

Mostly for fun. That said, Prism is almost as powerful as CBE and just as usable. So we'll see where things go from here.

#### Prism and CBE

Prism works with the same mechanisms as CBE; new users of Prism who have been long-time users of CBE will feel right at home to start with.

```Lua
local vent = CBE.newVent({
  [params]
})

local emitter = prism.newEmitter({
  [params]
})
```

The biggest difference between Prism and CBE is that, where CBE traded in simplicity to get maximum power, Prism trades in power to get maximum simplicity. The end result is an easy-to-use and well-organized particle system with the same basic thinking that CBE has.

Some examples of where this difference in philosophy has taken effect:
- CBE is a folder so that it can be a package of everything but the kitchen sink. Prism is a single file for portability and plug-and-play-ness.
- CBE uses callbacks so that you can use listeners straight from the parameters to get right into the action. Prism uses Corona's event listeners because they feel more "native".
- CBE has effect fields for maximum power. Prism skips them to keep things simple.
- CBE uses a `build` function to get particles. Prism allows you to specify just the particle type, size, and other parameters and builds particles itself.
- CBE has a dedicated structure built just for combining and managing multiple vents. Prism just has the emitter structure.

I could go on and on, but I think you get the point.

All of that to say, Prism isn't just a barely customizeable hand-holding wimpy little brother of CBE. Prism has the capabilities to create just about the same effects CBE can. It's just engineered for simplicity.

#### Got it. Let's begin.

Start by running `main.lua` in the Corona Simulator, then edit the code and try out different parameters. You can find every possible parameter in `parameters.txt`. Experiment, and see how things work. I'll think about writing docs if this gets off the ground - right now, it's just a hobby project for fun.
