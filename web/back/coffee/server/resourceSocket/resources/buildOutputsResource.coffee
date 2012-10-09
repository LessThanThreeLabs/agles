assert = require 'assert'

Resource = require './resource'


exports.create = (modelRpcConnection) ->
	return new BuildOutputsResource modelRpcConnection


class BuildOutputsResource extends Resource
	read: (socket, data, callback) ->
		fakeOutput = 
			text: story
		callback null, fakeOutput
		



story = ["There was a spatter of pebbles against the window and the youngster stirred in his sleep. Another, and he was awake.",

"He sat up stiffly in bed. Seconds passed while he interpreted his strange surroundings. He wasn't in his own home, of course. This was out in the country. It was colder than it should be and there was green at the window.",

"Slim!",

"The call was a hoarse, urgent whisper, and the youngster bounded to the",
"open window.",

"Slim wasn't his real name, but the new friend he had met the day before",
"had needed only one look at his slight figure to say, You're Slim. He",
"added, I'm Red.",

"Red wasn't his real name, either, but its appropriateness was obvious.",
"They were friends instantly with the quick unquestioning friendship of",
"young ones not yet quite in adolescence, before even the first stains of",
"adulthood began to make their appearance.",

"Slim cried, Hi, Red! and waved cheerfully, still blinking the sleep",
"out of himself.",

"Red kept to his croaking whisper, Quiet! You want to wake somebody?",

"Slim noticed all at once that the sun scarcely topped the low hills in",
"the east, that the shadows were long and soft, and that the grass was",
"wet.",

"Slim said, more softly, What's the matter?",

"Red only waved for him to come out.",

"Slim dressed quickly, gladly confining his morning wash to the momentary",
"sprinkle of a little lukewarm water. He let the air dry the exposed",
"portions of his body as he ran out, while bare skin grew wet against the",
"dewy grass.",

"Red said, You've got to be quiet. If Mom wakes up or Dad or your Dad or",
"even any of the hands then it'll be 'Come on in or you'll catch your",
"death of cold.'",

"He mimicked voice and tone faithfully, so that Slim laughed and thought",
"that there had never been so funny a fellow as Red.",

"Slim said, eagerly, Do you come out here every day like this, Red? Real",
"early? It's like the whole world is just yours, isn't it, Red? No one",
"else around and all like that. He felt proud at being allowed entrance",
"into this private world.",

"Red stared at him sidelong. He said carelessly, I've been up for hours.",
"Didn't you hear it last night?",

"Hear what?",

"Thunder.",

"Was there a thunderstorm? Slim never slept through a thunderstorm.",

"I guess not. But there was thunder. I heard it, and then I went to the",
"window and it wasn't raining. It was all stars and the sky was just",
"getting sort of almost gray. You know what I mean?",

"Slim had never seen it so, but he nodded.",

"So I just thought I'd go out, said Red.",

"They walked along the grassy side of the concrete road that split the",
"panorama right down the middle all the way down to where it vanished",
"among the hills. It was so old that Red's father couldn't tell Red when",
"it had been built. It didn't have a crack or a rough spot in it.",

"Red said, Can you keep a secret?",

"Sure, Red. What kind of a secret?",

"Just a secret. Maybe I'll tell you and maybe I won't. I don't know",
"yet. Red broke a long, supple stem from a fern they passed,",
"methodically stripped it of its leaflets and swung what was left",
"whip-fashion. For a moment, he was on a wild charger, which reared and",
"champed under his iron control. Then he got tired, tossed the whip aside",
"and stowed the charger away in a corner of his imagination for future",
"use.",

"He said, There'll be a circus around.",

"Slim said, That's no secret. I knew that. My Dad told me even before we",
"came here--",

"That's not the secret. Fine secret! Ever see a circus?",

"Oh, sure. You bet.",

"Like it?",

"Say, there isn't anything I like better.",

"Red was watching out of the corner of his eyes again. Ever think you",
"would like to be with a circus? I mean, for good?",

"Slim considered, I guess not. I think I'll be an astronomer like my",
"Dad. I think he wants me to be.",

"Huh! Astronomer! said Red.",

"Slim felt the doors of the new, private world closing on him and",
"astronomy became a thing of dead stars and black, empty space.",

"He said, placatingly, A circus _would_ be more fun.",

"You're just saying that.",

"No, I'm not. I mean it.",

"Red grew argumentative. Suppose you had a chance to join the circus",
"right now. What would you do?",

"I--I--",

"See! Red affected scornful laughter.",

"Slim was stung. I'd join up.",

"Go on.",

"Try me.",

"Red whirled at him, strange and intense. You meant that? You want to go",
"in with me?",

"[Illustration]",

"What do you mean? Slim stepped back a bit, surprised by the unexpected",
"challenge.",

"I got something that can get us into the circus. Maybe someday we can",
"even have a circus of our own. We could be the biggest circus-fellows in",
"the world. That's if you want to go in with me. Otherwise--Well, I guess",
"I can do it on my own. I just thought: Let's give good old Slim a",
"chance."]

# "The world was strange and glamorous, and Slim said, Sure thing, Red.",
# "I'm in! What is it, huh, Red? Tell me what it is.",

# "Figure it out. What's the most important thing in circuses?",

# "Slim thought desperately. He wanted to give the right answer. Finally,",
# "he said, Acrobats?",

# "Holy Smokes! I wouldn't go five steps to look at acrobats.",

# "I don't know then.",

# "Animals, that's what! What's the best side-show? Where are the biggest",
# "crowds? Even in the main rings the best acts are animal acts. There was",
# "no doubt in Red's voice.",

# "Do you think so?",

# "Everyone thinks so. You ask anyone. Anyway, I found animals this",
# "morning. Two of them.",

# "And you've got them?",

# "Sure. That's the secret. Are you telling?",

# "Of course not.",

# "Okay. I've got them in the barn. Do you want to see them?",

# "They were almost at the barn; its huge open door black. Too black. They",
# "had been heading there all the time. Slim stopped in his tracks.",

# "He tried to make his words casual. Are they big?",

# "Would I fool with them if they were big? They can't hurt you. They're",
# "only about so long. I've got them in a cage.",

# "They were in the barn now and Slim saw the large cage suspended from a",
# "hook in the roof. It was covered with stiff canvas.",

# "Red said, We used to have some bird there or something. Anyway, they",
# "can't get away from there. Come on, let's go up to the loft.",

# "They clambered up the wooden stairs and Red hooked the cage toward them.",

# "Slim pointed and said, There's sort of a hole in the canvas.",

# "Red frowned. How'd that get there? He lifted the canvas, looked in,",
# "and said, with relief, They're still there.",

# "The canvas appeared to be burned, worried Slim.",

# "You want to look, or don't you?",

# "Slim nodded slowly. He wasn't sure he wanted to, after all. They might",
# "be--",

# "But the canvas had been jerked off and there they were. Two of them, the",
# "way Red said. They were small, and sort of disgusting-looking. The",
# "animals moved quickly as the canvas lifted and were on the side toward",
# "the youngsters. Red poked a cautious finger at them.",

# "Watch out, said Slim, in agony.",

# "They don't hurt you, said Red. Ever see anything like them?",

# "No.",

# "Can't you see how a circus would jump at a chance to have these?",

# "Maybe they're too small for a circus.",

# "Red looked annoyed. He let go the cage which swung back and forth",
# "pendulum-fashion. You're just trying to back out, aren't you?",

# "No, I'm not. It's just--",

# "They're not too small, don't worry. Right now, I've only got one",
# "worry.",

# "What's that?",

# "Well, I've got to keep them till the circus comes, don't I? I've got",
# "to figure out what to feed them meanwhile.",

# "The cage swung and the little trapped creatures clung to its bars,",
# "gesturing at the youngsters with queer, quick motions--almost as though",
# "they were intelligent.",

# "",
# "II",

# "The Astronomer entered the dining room with decorum. He felt very much",
# "the guest.",

# "He said, Where are the youngsters? My son isn't in his room.",

# "The Industrialist smiled. They've been out for hours. However,",
# "breakfast was forced into them among the women some time ago, so there",
# "is nothing to worry about. Youth, Doctor, youth!",

# "Youth! The word seemed to depress the Astronomer.",

# "They ate breakfast in silence. The Industrialist said once, You really",
# "think they'll come. The day looks so--_normal_.",

# "The Astronomer said, They'll come.",

# "That was all.",

# "Afterward the Industrialist said, You'll pardon me. I can't conceive",
# "your playing so elaborate a hoax. You really spoke to them?",

# "As I speak to you. At least, in a sense. They can project thoughts.",

# "I gathered that must be so from your letter. How, I wonder.",

# "I could not say. I asked them and, of course, they were vague. Or",
# "perhaps it was just that I could not understand. It involves a projector",
# "for the focussing of thought and, even more than that, conscious",
# "attention on the part of both projector and receptor. It was quite a",
# "while before I realized they were trying to think at me. Such",
# "thought-projectors may be part of the science they will give us.",

# "Perhaps, said the Industrialist. Yet think of the changes it would",
# "bring to society. A thought-projector!",

# "Why not? Change would be good for us.",

# "I don't think so.",

# "It is only in old age that change is unwelcome, said the Astronomer,",
# "and races can be old as well as individuals.",

# "The Industrialist pointed out the window. You see that road. It was",
# "built Beforethewars. I don't know exactly when. It is as good now as the",
# "day it was built. We couldn't possibly duplicate it now. The race was",
# "young when that was built, eh?",

# "Then? Yes! At least they weren't afraid of new things.",

# "No. I wish they had been. Where is the society of Beforethewars?",
# "Destroyed, Doctor! What good were youth and new things? We are better",
# "off now. The world is peaceful and jogs along. The race goes nowhere but",
# "after all, there is nowhere to go. _They_ proved that. The men who built",
# "the road. I will speak with your visitors as I agreed, if they come. But",
# "I think I will only ask them to go.",

# "The race is not going nowhere, said the Astronomer, earnestly. It is",
# "going toward final destruction. My university has a smaller student body",
# "each year. Fewer books are written. Less work is done. An old man sleeps",
# "in the sun and his days are peaceful and unchanging, but each day finds",
# "him nearer death all the same.",

# "Well, well, said the Industrialist.",

# "No, don't dismiss it. Listen. Before I wrote you, I investigated your",
# "position in the planetary economy.",

# "And you found me solvent? interrupted the Industrialist, smiling.",

# "Why, yes. Oh, I see, you are joking. And yet--perhaps the joke is not",
# "far off. You are less solvent than your father and he was less solvent",
# "than his father. Perhaps your son will no longer be solvent. It becomes",
# "too troublesome for the planet to support even the industries that still",
# "exist, though they are toothpicks to the oak trees of Beforethewars. We",
# "will be back to village economy and then to what? The caves?",

# "And the infusion of fresh technological knowledge will be the changing",
# "of all that?",

# "Not just the new knowledge. Rather the whole effect of change, of a",
# "broadening of horizons. Look, sir, I chose you to approach in this",
# "matter not only because you were rich and influential with government",
# "officials, but because you had an unusual reputation, for these days, of",
# "daring to break with tradition. Our people will resist change and you",
# "would know how to handle them, how to see to it that--that--",

# "That the youth of the race is revived?",

# "Yes.",

# "With its atomic bombs?",

# "The atomic bombs, returned the Astronomer, need not be the end of",
# "civilization. These visitors of mine had their atomic bomb, or whatever",
# "their equivalent was on their own worlds, and survived it, because they",
# "didn't give up. Don't you see? It wasn't the bomb that defeated us, but",
# "our own shell shock. This may be the last chance to reverse the",
# "process.",

# "[Illustration]",

# "Tell me, said the Industrialist, what do these friends from space",
# "want in return?",

# "The Astronomer hesitated. He said, I will be truthful with you. They",
# "come from a denser planet. Ours is richer in the lighter atoms.",

# "They want magnesium? Aluminum?",

# "No, sir. Carbon and hydrogen. They want coal and oil.",

# "Really?",

# "The Astronomer said, quickly, You are going to ask why creatures who",
# "have mastered space travel, and therefore atomic power, would want coal",
# "and oil. I can't answer that.",

# "The Industrialist smiled. But I can. This is the best evidence yet of",
# "the truth of your story. Superficially, atomic power would seem to",
# "preclude the use of coal and oil. However, quite apart from the energy",
# "gained by their combustion they remain, and always will remain, the",
# "basic raw material for all organic chemistry. Plastics, dyes,",
# "pharmaceuticals, solvents. Industry could not exist without them, even",
# "in an atomic age. Still, if coal and oil are the low price for which",
# "they would sell us the troubles and tortures of racial youth, my answer",
# "is that the commodity would be dear if offered gratis.",

# "The Astronomer sighed and said, There are the boys!",

# "They were visible through the open window, standing together in the",
# "grassy field and lost in animated conversation. The Industrialist's son",
# "pointed imperiously and the Astronomer's son nodded and made off at a",
# "run toward the house.",

# "The Industrialist said, There is the Youth you speak of. Our race has",
# "as much of it as it ever had.",

# "Yes, but we age them quickly and pour them into the mold.",

# "Slim scuttled into the room, the door banging behind him.",

# "The Astronomer said, in mild disapproval, What's this?",

# "Slim looked up in surprise and came to a halt. I beg your pardon. I",
# "didn't know anyone was here. I am sorry to have interrupted. His",
# "enunciation was almost painfully precise.",

# "The Industrialist said, It's all right, youngster.",

# "But the Astronomer said, Even if you had been entering an empty room,",
# "son, there would be no cause for slamming a door.",

# "Nonsense, insisted the Industrialist. The youngster has done no harm.",
# "You simply scold him for being young. You, with your views!",

# "He said to Slim, Come here, lad.",

# "Slim advanced slowly.",

# "How do you like the country, eh?",

# "Very much, sir, thank you.",

# "My son has been showing you about the place, has he?",

# "Yes, sir. Red--I mean--",

# "No, no. Call him Red. I call him that myself. Now tell me, what are you",
# "two up to, eh?",

# "Slim looked away. Why--just exploring, sir.",

# "The Industrialist turned to the Astronomer. There you are, youthful",
# "curiosity and adventure-lust. The race has not yet lost it.",

# "Slim said, Sir?",

# "Yes, lad.",

# "The youngster took a long time in getting on with it. He said, Red sent",
# "me in for something good to eat, but I don't exactly know what he meant.",
# "I didn't like to say so.",

# "Why, just ask cook. She'll have something good for young'uns to eat.",

# "Oh, no, sir. I mean for animals.",

# "For animals?",

# "Yes, sir. What do animals eat?",

# "The Astronomer said, I am afraid my son is city-bred.",

# "Well, said the Industrialist, there's no harm in that. What kind of",
# "an animal, lad?",

# "A small one, sir.",

# "Then try grass or leaves, and if they don't want that, nuts or berries",
# "would probably do the trick.",

# "Thank you, sir. Slim ran out again, closing the door gently behind",
# "him.",

# "The Astronomer said, Do you suppose they've trapped an animal alive?",
# "He was obviously perturbed.",

# "That's common enough. There's no shooting on my estate and it's tame",
# "country, full of rodents and small creatures. Red is always coming home",
# "with pets of one sort or another. They rarely maintain his interest for",
# "long.",

# "He looked at the wall clock. Your friends should have been here by now,",
# "shouldn't they?",

# "",
# "III",

# "The swaying had come to a halt and it was dark. The Explorer was not",
# "comfortable in the alien air. It felt as thick as soup and he had to",
# "breathe shallowly. Even so--",

# "He reached out in a sudden need for company. The Merchant was warm to",
# "the touch. His breathing was rough, he moved in an occasional spasm, and",
# "was obviously asleep. The Explorer hesitated and decided not to wake",
# "him. It would serve no real purpose.",

# "There would be no rescue, of course. That was the penalty paid for the",
# "high profits which unrestrained competition could lead to. The Merchant",
# "who opened a new planet could have a ten year monopoly of its trade,",
# "which he might hug to himself or, more likely, rent out to all comers at",
# "a stiff price. It followed that planets were searched for in secrecy",
# "and, preferably, away from the usual trade routes. In a case such as",
# "theirs, then, there was little or no chance that another ship would come",
# "within range of their subetherics except for the most improbable of",
# "coincidences. Even if they were in their ship, that is, rather than in",
# "this--this--_cage_.",

# "The Explorer grasped the thick bars. Even if they blasted those away, as",
# "they could, they would be stuck too high in open air for leaping.",

# "It was too bad. They had landed twice before in the scout-ship. They had",
# "established contact with the natives who were grotesquely huge, but mild",
# "and unaggressive. It was obvious that they had once owned a flourishing",
# "technology, but hadn't faced up to the consequences of such a",
# "technology. It would have been a wonderful market.",

# "And it was a tremendous world. The Merchant, especially, had been taken",
# "aback. He had known the figures that expressed the planet's diameter,",
# "but from a distance of two light-seconds, he had stood at the visi-plate",
# "and muttered, Unbelievable!",

# "Oh, there are larger worlds, the Explorer said. It wouldn't do for an",
# "Explorer to be too easily impressed.",

# "Inhabited?",

# "Well, no.",

# "Why, you could drop your planet into that large ocean and drown it.",

# "The Explorer smiled. It was a gentle dig at his Arcturian homeland,",
# "which was smaller than most planets. He said, Not quite.",

# "The Merchant followed along the line of his thoughts. And the",
# "inhabitants are large in proportion to their world? He sounded as",
# "though the news struck him less favorably now.",

# "Nearly ten times our height.",

# "Are you sure they are friendly?",

# "That is hard to say. Friendship between alien intelligences is an",
# "imponderable. They are not dangerous, I think. We've come across other",
# "groups that could not maintain equilibrium after the atomic war stage",
# "and you know the results. Introversion. Retreat. Gradual decadence and",
# "increasing gentleness.",

# "Even if they are such monsters?",

# "The principle remains.",

# "It was about then that the Explorer felt the heavy throbbing of the",
# "engines.",

# "He frowned and said, We are descending a bit too quickly.",

# "There had been some speculation on the dangers of landing some hours",
# "before. The planetary target was a huge one for an oxygen-water world.",
# "Though it lacked the size of the uninhabitable hydrogen-ammonia planets",
# "and its low density made its surface gravity fairly normal, its",
# "gravitational forces fell off but slowly with distance. In short, its",
# "gravitational potential was high and the ship's Calculator was a",
# "run-of-the-mill model not designed to plot landing trajectories at that",
# "potential range. That meant the Pilot would have to use manual controls.",

# "It would have been wiser to install a more high-powered model, but that",
# "would have meant a trip to some outpost of civilization; lost time;",
# "perhaps a lost secret. The Merchant demanded an immediate landing.",

# "The Merchant felt it necessary to defend his position now. He said",
# "angrily to the Explorer, Don't you think the Pilot knows his job? He",
# "landed you safely twice before.",

# "Yes, thought the Explorer, in a scout-ship, not in this unmaneuverable",
# "freighter. Aloud, he said nothing.",

# "He kept his eye on the visi-plate. They were descending too quickly.",
# "There was no room for doubt. Much too quickly.",

# "The Merchant said, peevishly, Why do you keep silence?",

# "Well, then, if you wish me to speak, I would suggest that you strap on",
# "your Floater and help me prepare the Ejector.",

# "The Pilot fought a noble fight. He was no beginner. The atmosphere,",
# "abnormally high and thick in the gravitational potential of this world",
# "whipped and burned about the ship, but to the very last it looked as",
# "though he might bring it under control despite that.",

# "He even maintained course, following the extrapolated line to the point",
# "on the northern continent toward which they were headed. Under other",
# "circumstances, with a shade more luck, the story would eventually have",
# "been told and retold as a heroic and masterly reversal of a lost",
# "situation. But within sight of victory, tired body and tired nerves",
# "clamped a control bar with a shade too much pressure. The ship, which",
# "had almost levelled off, dipped down again.",

# "There was no room to retrieve the final error. There was only a mile",
# "left to fall. The Pilot remained at his post to the actual landing, his",
# "only thought that of breaking the force of the crash, of maintaining the",
# "spaceworthiness of the vessel. He did not survive. With the ship bucking",
# "madly in a soupy atmosphere, few Ejectors could be mobilized and only",
# "one of them in time.",

# "When afterwards, the Explorer lifted out of unconsciousness and rose",
# "to his feet, he had the definite feeling that but for himself and",
# "the Merchant, there were no survivors. And perhaps that was an",
# "over-calculation. His Floater had burnt out while still sufficiently",
# "distant from surface to have the fall stun him. The Merchant might have",
# "had less luck, even, than that.",

# "He was surrounded by a world of thick, ropy stalks of grass, and in the",
# "distance were trees that reminded him vaguely of similar structures on",
# "his native Arcturian world except that their lowest branches were high",
# "above what he would consider normal tree-tops.",

# "He called, his voice sounding basso in the thick air and the Merchant",
# "answered. The Explorer made his way toward him, thrusting violently at",
# "the coarse stalks that barred his path.",

# "Are you hurt? he asked.",

# "The Merchant grimaced. I've sprained something. It hurts to walk.",

# "The Explorer probed gently. I don't think anything is broken. You'll",
# "have to walk despite the pain.",

# "Can't we rest first?",

# "It's important to try to find the ship. If it is spaceworthy or if it",
# "can be repaired, we may live. Otherwise, we won't.",

# "Just a few minutes. Let me catch my breath.",

# "The Explorer was glad enough for those few minutes. The Merchant's eyes",
# "were already closed. He allowed his to do the same.",

# "He heard the trampling and his eyes snapped open. Never sleep on a",
# "strange planet, he told himself futilely.",

# "The Merchant was awake too and his steady screaming was a rumble of",
# "terror.",

# "The Explorer called, It's only a native of this planet. It won't harm",
# "you.",

# "But even as he spoke, the giant had swooped down and in a moment they",
# "were in its grasp being lifted closer to its monstrous ugliness.",

# "The Merchant struggled violently and, of course, quite futilely. Can't",
# "you talk to it? he yelled.",

# "The Explorer could only shake his head. I can't reach it with the",
# "Projector. It won't be listening.",

# "Then blast it. Blast it down.",

# "We can't do that. The phrase you fool had almost been added. The",
# "Explorer struggled to keep his self-control. They were swallowing space",
# "as the monster moved purposefully away.",

# "Why not? cried the Merchant. You can reach your blaster. I see it in",
# "plain sight. Don't be afraid of falling.",

# "It's simpler than that. If this monster is killed, you'll never trade",
# "with this planet. You'll never even leave it. You probably won't live",
# "the day out.",

# "Why? Why?",

# "Because this is one of the young of the species. You should know what",
# "happens when a trader kills a native young, even accidentally. What's",
# "more, if this is the target-point, then we are on the estate of a",
# "powerful native. This might be one of his brood.",

# "That was how they entered their present prison. They had carefully burnt",
# "away a portion of the thick, stiff covering and it was obvious that the",
# "height from which they were suspended was a killing one.",

# "Now, once again, the prison-cage shuddered and lifted in an upward arc.",
# "The Merchant rolled to the lower rim and startled awake. The cover",
# "lifted and light flooded in. As was the case the time before, there were",
# "two specimens of the young. They were not very different in appearance",
# "from adults of the species, reflected the Explorer, though, of course,",
# "they were considerably smaller.",

# "A handful of reedy green stalks was stuffed between the bars. Its odor",
# "was not unpleasant but it carried clods of soil at its ends.",

# "The Merchant drew away and said, huskily, What are they doing?",

# "The Explorer said, Trying to feed us, I should judge. At least this",
# "seems to be the native equivalent of grass.",

# "The cover was replaced and they were set swinging again, alone with",
# "their fodder.",

# "",
# "IV",

# "Slim started at the sound of footsteps and brightened when it turned out",
# "to be only Red.",

# "He said, No one's around. I had my eye peeled, you bet.",

# "Red said, Ssh. Look. You take this stuff and stick it in the cage. I've",
# "got to scoot back to the house.",

# "What is it? Slim reached reluctantly.",

# "Ground meat. Holy Smokes, haven't you ever seen ground meat? That's",
# "what you should've got when I sent you to the house instead of coming",
# "back with that stupid grass.",

# "Slim was hurt. How'd I know they don't eat grass. Besides, ground meat",
# "doesn't come loose like that. It comes in cellophane and it isn't that",
# "color.",

# "Sure--in the city. Out here we grind our own and it's always this color",
# "till it's cooked.",

# "You mean it isn't cooked? Slim drew away quickly.",

# "Red looked disgusted. Do you think animals eat _cooked_ food. Come on,",
# "take it. It won't hurt you. I tell you there isn't much time.",

# "Why? What's doing back at the house?",

# "I don't know. Dad and your father are walking around. I think maybe",
# "they're looking for me. Maybe the cook told them I took the meat.",
# "Anyway, we don't want them coming here after me.",

# "Didn't you ask the cook before you took this stuff?",

# "Who? That crab? Shouldn't wonder if she only let me have a drink of",
# "water because Dad makes her. Come on. Take it.",

# "Slim took the large glob of meat though his skin crawled at the touch.",
# "He turned toward the barn and Red sped away in the direction from which",
# "he had come.",

# "He slowed when he approached the two adults, took a few deep breaths to",
# "bring himself back to normal, and then carefully and nonchalantly",
# "sauntered past. (They were walking in the general direction of the barn,",
# "he noticed, but not dead on.)",

# "He said, Hi, Dad. Hello, sir.",

# "The Industrialist said, Just a moment, Red. I have a question to ask",
# "you?",

# "Red turned a carefully blank face to his father. Yes, Dad?",

# "Mother tells me you were out early this morning.",

# "Not real early, Dad. Just a little before breakfast.",

# "She said you told her it was because you had been awakened during the",
# "night and didn't go back to sleep.",

# "Red waited before answering. Should he have told Mom that?",

# "Then he said, Yes, sir.",

# "What was it that awakened you?",

# "Red saw no harm in it. He said, I don't know, Dad. It sounded like",
# "thunder, sort of, and like a collision, sort of.",

# "Could you tell where it came from?",

# "It _sounded_ like it was out by the hill. That was truthful, and",
# "useful as well, since the direction was almost opposite that in which",
# "the barn lay.",

# "The Industrialist looked at his guest. I suppose it would do no harm to",
# "walk toward the hill.",

# "The Astronomer said, I am ready.",

# "Red watched them walk away and when he turned he saw Slim peering",
# "cautiously out from among the briars of a hedge.",

# "Red waved at him. Come on.",

# "Slim stepped out and approached. Did they say anything about the meat?",

# "No. I guess they don't know about that. They went down to the hill.",

# "What for?",

# "Search me. They kept asking about the noise I heard. Listen, did the",
# "animals eat the meat?",

# "Well, said Slim, cautiously, they were sort of _looking_ at it and",
# "smelling it or something.",

# "Okay, Red said, I guess they'll eat it. Holy Smokes, they've got to",
# "eat _something_. Let's walk along toward the hill and see what Dad and",
# "your father are going to do.",

# "What about the animals?",

# "They'll be all right. A fellow can't spend all his time on them. Did",
# "you give them water?",

# "Sure. They drank that.",

# "See. Come on. We'll look at them after lunch. I tell you what. We'll",
# "bring them fruit. Anything'll eat fruit.",

# "Together they trotted up the rise, Red, as usual, in the lead.",

# "",
# "V",

# "The Astronomer said, You think the noise was their ship landing?",

# "Don't you think it could be?",

# "If it were, they may all be dead.",

# "Perhaps not. The Industrialist frowned.",

# "If they have landed, and are still alive, where are they?",

# "Think about that for a while. He was still frowning.",

# "The Astronomer said, I don't understand you.",

# "They may not be friendly.",

# "Oh, no. I've spoken with them. They've--",

# "You've spoken with them. Call that reconnaissance. What would their",
# "next step be? Invasion?",

# "But they only have one ship, sir.",

# "You know that only because they say so. They might have a fleet.",

# "I've told you about their size. They--",

# "Their size would not matter, if they have handweapons that may well be",
# "superior to our artillery.",

# "That is not what I meant.",

# "I had this partly in mind from the first. The Industrialist went on.",
# "It is for that reason I agreed to see them after I received your",
# "letter. Not to agree to an unsettling and impossible trade, but to judge",
# "their real purposes. I did not count on their evading the meeting.",

# "He sighed. I suppose it isn't our fault. You are right in one thing, at",
# "any rate. The world has been at peace too long. We are losing a healthy",
# "sense of suspicion.",

# "The Astronomer's mild voice rose to an unusual pitch and he said, I",
# "_will_ speak. I tell you that there is no reason to suppose they can",
# "possibly be hostile. They are small, yes, but that is only important",
# "because it is a reflection of the fact that their native worlds are",
# "small. Our world has what is for them a normal gravity, but because of",
# "our much higher gravitational potential, our atmosphere is too dense to",
# "support them comfortably over sustained periods. For a similar reason",
# "the use of the world as a base for interstellar travel, except for trade",
# "in certain items, is uneconomical. And there are important differences",
# "in chemistry of life due to the basic differences in soils. They",
# "couldn't eat our food or we theirs.",

# "Surely all this can be overcome. They can bring their own food, build",
# "domed stations of lowered air pressure, devise specially designed",
# "ships.",

# "They can. And how glibly you can describe feats that are easy to a race",
# "in its youth. It is simply that they don't have to do any of that. There",
# "are millions of worlds suitable for them in the Galaxy. They don't need",
# "this one which isn't.",

# "How do you know? All this is their information again.",

# "This I was able to check independently. I am an astronomer, after all.",

# "That is true. Let me hear what you have to say then, while we walk.",

# "Then, sir, consider that for a long time our astronomers have believed",
# "that two general classes of planetary bodies existed. First, the planets",
# "which formed at distances far enough from their stellar nucleus to",
# "become cool enough to capture hydrogen. These would be large planets",
# "rich in hydrogen, ammonia and methane. We have examples of these in the",
# "giant outer planets. The second class would include those planets formed",
# "so near the stellar center that the high temperature would make it",
# "impossible to capture much hydrogen. These would be smaller planets,",
# "comparatively poorer in hydrogen and richer in oxygen. We know that type",
# "very well since we live on one. Ours is the only solar system we know in",
# "detail, however, and it has been reasonable for us to assume that these",
# "were the _only_ two planetary classes.",

# "I take it then that there is another.",

# "Yes. There is a super-dense class, still smaller, poorer in hydrogen,",
# "than the inner planets of the solar system. The ratio of occurrence of",
# "hydrogen-ammonia planets and these super-dense water-oxygen worlds of",
# "theirs over the entire Galaxy--and remember that they have actually",
# "conducted a survey of significant sample volumes of the Galaxy which we,",
# "without interstellar travel, cannot do--is about 3 to 1. This leaves",
# "them seven million super-dense worlds for exploration and colonization.",

# "The Industrialist looked at the blue sky and the green-covered trees",
# "among which they were making their way. He said, And worlds like ours?",

# "The Astronomer said, softly, Ours is the first solar system they have",
# "found which contains them. Apparently the development of our solar",
# "system was unique and did not follow the ordinary rules.",

# "The Industrialist considered that. What it amounts to is that these",
# "creatures from space are asteroid-dwellers.",

# "No, no. The asteroids are something else again. They occur, I was told,",
# "in one out of eight stellar systems, but they're completely different",
# "from what we've been discussing.",

# "And how does your being an astronomer change the fact that you are",
# "still only quoting their unsupported statements?",

# "But they did not restrict themselves to bald items of information. They",
# "presented me with a theory of stellar evolution which I had to accept",
# "and which is more nearly valid than anything our own astronomy has ever",
# "been able to devise, if we except possible lost theories dating from",
# "Beforethewars. Mind you, their theory had a rigidly mathematical",
# "development and it predicted just such a Galaxy as they describe. So you",
# "see, they have all the worlds they wish. They are not land-hungry.",
# "Certainly not for our land.",

# "Reason would say so, if what you say is true. But creatures may be",
# "intelligent and not reasonable. Our forefathers were presumably",
# "intelligent, yet they were certainly not reasonable. Was it reasonable",
# "to destroy almost all their tremendous civilization in atomic warfare",
# "over causes our historians can no longer accurately determine? The",
# "Industrialist brooded over it. From the dropping of the first atom bomb",
# "over those islands--I forget the ancient name--there was only one end in",
# "sight, and in plain sight. Yet events were allowed to proceed to that",
# "end.",

# "He looked up, said briskly, Well, where are we? I wonder if we are not",
# "on a fool's errand after all.",

# "But the Astronomer was a little in advance and his voice came thickly.",
# "No fool's errand, sir. Look there.",

# "",
# "VI",

# "Red and Slim had trailed their elders with the experience of youth,",
# "aided by the absorption and anxiety of their fathers. Their view of the",
# "final object of the search was somewhat obscured by the underbrush",
# "behind which they remained.",

# "Red said, Holy Smokes. Look at that. It's all shiny silver or",
# "something.",

# "But it was Slim who was really excited. He caught at the other. I know",
# "what this is. It's a space-ship. That must be why my father came here.",
# "He's one of the biggest astronomers in the world and your father would",
# "have to call him if a space-ship landed on his estate.",

# "What are you talking about? Dad didn't even know that thing was there.",
# "He only came here because I told him I heard the thunder from here.",
# "Besides, there isn't any such thing as a space-ship.",

# "Sure, there is. Look at it. See those round things. They are ports. And",
# "you can see the rocket tubes.",

# "How do you know so much?",

# "Slim was flushed. He said, I read about them. My father has books about",
# "them. Old books. From Beforethewars.",

# "Huh. Now I know you're making it up. Books from Beforethewars!",

# "My father _has_ to have them. He teaches at the University. It's his",
# "job.",

# "His voice had risen and Red had to pull at him. You want them to hear",
# "us? he whispered indignantly.",

# "Well, it is, too, a space-ship.",

# "Look here, Slim, you mean that's a ship from another world.",

# "It's _got_ to be. Look at my father going round and round it. He",
# "wouldn't be so interested if it was anything else.",

# "Other worlds! Where are there other worlds?",

# "Everywhere. How about the planets? They're worlds just like ours, some",
# "of them. And other stars probably have planets. There's probably",
# "zillions of planets.",

# "Red felt outweighed and outnumbered. He muttered, You're crazy!",

# "All right, then. I'll show you.",

# "Hey! Where are you going?",

# "Down there. I'm going to ask my father. I suppose you'll believe it if",
# "_he_ tells you. I suppose you'll believe a Professor of Astronomy knows",
# "what--",

# "He had scrambled upright.",

# "Red said, Hey. You don't want them to see us. We're not supposed to be",
# "here. Do you want them to start asking questions and find out about our",
# "animals?",

# "I don't care. You said I was crazy.",

# "Snitcher! You promised you wouldn't tell.",

# "I'm _not_ going to tell. But if they find out themselves, it's your",
# "fault, for starting an argument and saying I was crazy.",

# "I take it back, then, grumbled Red.",

# "Well, all right. You better.",

# "In a way, Slim was disappointed. He wanted to see the space-ship at",
# "closer quarters. Still, he could not break his vow of secrecy even in",
# "spirit without at least the excuse of personal insult.",

# "Red said, It's awfully small for a space-ship.",

# "Sure, because it's probably a scout-ship.",

# "I'll bet Dad couldn't even get into the old thing.",

# "So much Slim realized to be true. It was a weak point in his argument",
# "and he made no answer. His interest was absorbed by the adults.",

# "Red rose to his feet; an elaborate attitude of boredom all about him.",
# "Well, I guess we better be going. There's business to do and I can't",
# "spend all day here looking at some old space-ship or whatever it is.",
# "We've got to take care of the animals if we're going to be circus-folks.",
# "That's the first rule with circus-folks. They've got to take care of the",
# "animals. And, he finished virtuously, that's what I aim to do,",
# "anyway.",

# "Slim said, What for, Red? They've got plenty of meat. Let's watch.",

# "There's no fun in watching. Besides Dad and your father are going away",
# "and I guess it's about lunch time.",

# "Red became argumentative. Look, Slim, we can't start acting suspicious",
# "or they're going to start investigating. Holy Smokes, don't you ever",
# "read any detective stories? When you're trying to work a big deal",
# "without being caught, it's practically the main thing to keep on acting",
# "just like always. Then they don't suspect anything. That's the first",
# "law--",

# "Oh, all right.",

# "Slim rose resentfully. At the moment, the circus appeared to him a",
# "rather tawdry and shoddy substitute for the glories of astronomy, and he",
# "wondered how he had come to fall in with Red's silly scheme.",

# "Down the slope they went, Slim, as usual, in the rear.",

# "",
# "VII",

# "The Industrialist said, It's the workmanship that gets me. I never saw",
# "such construction.",

# "What good is it now? said the Astronomer, bitterly. There's nothing",
# "left. There'll be no second landing. This ship detected life on our",
# "planet through accident. Other exploring parties would come no closer",
# "than necessary to establish the fact that there were no super-dense",
# "worlds existing in our solar system.",

# "Well, there's no quarreling with a crash landing.",

# "The ship hardly seems damaged. If only some had survived, the ship",
# "might have been repaired.",

# "If they had survived, there would be no trade in any case. They're too",
# "different. Too disturbing. In any case--it's over.",

# "They entered the house and the Industrialist greeted his wife calmly.",
# "Lunch about ready, dear.",

# "I'm afraid not. You see-- She looked hesitantly at the Astronomer.",

# "Is anything wrong? asked the Industrialist. Why not tell me? I'm sure",
# "our guest won't mind a little family discussion.",

# "Pray don't pay any attention whatever to me, muttered the Astronomer.",
# "He moved miserably to the other end of the living room.",

# "The woman said, in low, hurried tones, Really, dear, cook's that upset.",
# "I've been soothing her for hours and honestly, I don't know why Red",
# "should have done it.",

# "Done what? The Industrialist was more amused than otherwise. It had",
# "taken the united efforts of himself and his son months to argue his wife",
# "into using the name Red rather than the perfectly ridiculous (viewed",
# "youngster fashion) name which was his real one.",

# "She said, He's taken most of the chopped meat.",

# "He's eaten it?",

# "Well, I hope not. It was raw.",

# "Then what would he want it for?",

# "I haven't the slightest idea. I haven't seen him since breakfast.",
# "Meanwhile cook's just furious. She caught him vanishing out the kitchen",
# "door and there was the bowl of chopped meat just about empty and she was",
# "going to use it for lunch. Well, you know cook. She had to change the",
# "lunch menu and that means she won't be worth living with for a week.",
# "You'll just have to speak to Red, dear, and make him promise not to do",
# "things in the kitchen any more. And it wouldn't hurt to have him",
# "apologize to cook.",

# "Oh, come. She works for us. If we don't complain about a change in",
# "lunch menu, why should she?",

# "Because she's the one who has double-work made for her, and she's",
# "talking about quitting. Good cooks aren't easy to get. Do you remember",
# "the one before her?",

# "It was a strong argument.",

# "The Industrialist looked about vaguely. He said, I suppose you're",
# "right. He isn't here, I suppose. When he comes in, I'll talk to him.",

# "You'd better start. Here he comes.",

# "Red walked into the house and said cheerfully, Time for lunch, I",
# "guess. He looked from one parent to the other in quick speculation at",
# "their fixed stares and said, Got to clean up first, though, and made",
# "for the other door.",

# "The Industrialist said, One moment, son.",

# "Sir?",

# "Where's your little friend?",

# "Red said, carelessly, He's around somewhere. We were just sort of",
# "walking and I looked around and he wasn't there. This was perfectly",
# "true, and Red felt on safe ground. I told him it was lunch time. I",
# "said, 'I suppose it's about lunch time.' I said, 'We got to be getting",
# "back to the house.' And he said, 'Yes.' And I just went on and then when",
# "I was about at the creek I looked around and--",

# "The Astronomer interrupted the voluble story, looking up from a",
# "magazine he had been sightlessly rummaging through. I wouldn't worry",
# "about my youngster. He is quite self-reliant. Don't wait lunch for him.",

# "Lunch isn't ready in any case, Doctor. The Industrialist turned once",
# "more to his son. And talking about that, son, the reason for it is that",
# "something happened to the ingredients. Do you have anything to say?",

# "Sir?",

# "I hate to feel that I have to explain myself more fully. Why did you",
# "take the chopped meat?",

# "The chopped meat?",

# "The chopped meat. He waited patiently.",

# "Red said, Well, I was sort of--",

# "Hungry? prompted his father. For raw meat?",

# "No, sir. I just sort of needed it.",

# "For what exactly?",

# "Red looked miserable and remained silent.",

# "The Astronomer broke in again. If you don't mind my putting in a few",
# "words--You'll remember that just after breakfast my son came in to ask",
# "what animals ate.",

# "Oh, you're right. How stupid of me to forget. Look here, Red, did you",
# "take it for an animal pet you've got?",

# "Red recovered indignant breath. He said, You mean Slim came in here and",
# "said I had an animal? He came in here and said that? He said I had an",
# "animal?",

# "No, he didn't. He simply asked what animals ate. That's all. Now if he",
# "promised he wouldn't tell on you, he didn't. It's your own foolishness",
# "in trying to take something without permission that gave you away. That",
# "happened to be stealing. Now have you an animal? I ask you a direct",
# "question.",

# "Yes, sir. It was a whisper so low as hardly to be heard.",

# "All right, you'll have to get rid of it. Do you understand?",

# "Red's mother intervened. Do you mean to say you're keeping a",
# "meat-eating animal, Red? It might bite you and give you blood-poison.",

# "They're only small ones, quavered Red. They hardly budge if you touch",
# "them.",

# "They? How many do you have?",

# "Two.",

# "Where are they?",

# "The Industrialist touched her arm. Don't chivvy the child any further,",
# "he said, in a low voice. If he says he'll get rid of them, he will,",
# "and that's punishment enough.",

# "He dismissed the matter from his mind.",

# "",
# "VIII",

# "Lunch was half over when Slim dashed into the dining room. For a moment,",
# "he stood abashed, and then he said in what was almost hysteria, I've",
# "got to speak to Red. I've got to say something.",

# "Red looked up in fright, but the Astronomer said, I don't think, son,",
# "you're being very polite. You've kept lunch waiting.",

# "I'm sorry, Father.",

# "Oh, don't rate the lad, said the Industrialist's wife. He can speak",
# "to Red if he wants to, and there was no damage done to the lunch.",

# "I've got to speak to Red alone, Slim insisted.",

# "Now that's enough, said the Astronomer with a kind of gentleness that",
# "was obviously manufactured for the benefit of strangers and which had",
# "beneath it an easily-recognized edge. Take your seat.",

# "Slim did so, but he ate only when someone looked directly upon him. Even",
# "then he was not very successful.",

# "Red caught his eyes. He made soundless words, Did the animals get",
# "loose?",

# "Slim shook his head slightly. He whispered, No, it's--",

# "The Astronomer looked at him hard and Slim faltered to a stop.",

# "With lunch over, Red slipped out of the room, with a microscopic motion",
# "at Slim to follow.",

# "They walked in silence to the creek.",

# "Then Red turned fiercely upon his companion. Look here, what's the idea",
# "of telling my Dad we were feeding animals?",

# "Slim said, I didn't. I asked what you feed animals. That's not the same",
# "as saying we were doing it. Besides, it's something else, Red.",

# "But Red had not used up his grievances. And where did you go anyway? I",
# "thought you were coming to the house. They acted like it was my fault",
# "you weren't there.",

# "But I'm trying to tell you about that, if you'd only shut _up_ a second",
# "and let me talk. You don't give a fellow a chance.",

# "Well, go on and tell me if you've got so much to say.",

# "I'm _trying_ to. I went back to the space-ship. The folks weren't there",
# "anymore and I wanted to see what it was like.",

# "It isn't a space-ship, said Red, sullenly. He had nothing to lose.",

# "It is, too. I looked inside. You could look through the ports and I",
# "looked inside and they were _dead_. He looked sick. They were dead.",

# "_Who_ were dead.",

# "Slim screeched, Animals! like _our_ animals! Only they _aren't_",
# "animals. They're people-things from other planets.",

# "For a moment Red might have been turned to stone. It didn't occur to him",
# "to disbelieve Slim at this point. Slim looked too genuinely the bearer",
# "of just such tidings. He said, finally, Oh, my.",

# "Well, what are we going to do? Golly, will we get a whopping if they",
# "find out? He was shivering.",

# "We better turn them loose, said Red.",

# "They'll tell on us.",

# "They can't talk our language. Not if they're from another planet.",

# "Yes, they can. Because I remember my father talking about some stuff",
# "like that to my mother when he didn't know I was in the room. He was",
# "talking about visitors who could talk with the mind. Telepathery or",
# "something. I thought he was making it up.",

# "Well, Holy Smokes. I mean--Holy Smokes. Red looked up. I tell you. My",
# "Dad said to get rid of them. Let's sort of bury them somewhere or throw",
# "them in the creek.",

# "He _told_ you to do that.",

# "He made me say I had animals and then he said, 'Get rid of them.' I got",
# "to do what he says. Holy Smokes, he's my Dad.",

# "Some of the panic left Slim's heart. It was a thoroughly legalistic way",
# "out. Well, let's do it right now, then, before they find out. Oh,",
# "golly, if they find out, will we be in trouble!",

# "They broke into a run toward the barn, unspeakable visions in their",
# "minds.",

# "",
# "IX",

# "It was different, looking at them as though they were people. As",
# "animals, they had been interesting; as people, horrible. Their eyes,",
# "which were neutral little objects before, now seemed to watch them with",
# "active malevolence.",

# "They're making noises, said Slim, in a whisper which was barely",
# "audible.",

# "I guess they're talking or something, said Red. Funny that those",
# "noises which they had heard before had not had significance earlier. He",
# "was making no move toward them. Neither was Slim.",

# "The canvas was off but they were just watching. The ground meat, Slim",
# "noticed, hadn't been touched.",

# "Slim said, Aren't you going to do something?",

# "Aren't you?",

# "You found them.",

# "It's your turn, now.",

# "No, it isn't. You found them. It's your fault, the whole thing. I was",
# "watching.",

# "You joined in, Slim. You know you did.",

# "I don't care. You found them and that's what I'll say when they come",
# "here looking for us.",

# "Red said, All right for you. But the thought of the consequences",
# "inspired him anyway, and he reached for the cage door.",

# "Slim said, Wait!",

# "Red was glad to. He said, Now what's biting you?",

# "One of them's got something on him that looks like it might be iron or",
# "something.",

# "Where?",

# "Right there. I saw it before but I thought it was just part of him. But",
# "if he's 'people,' maybe it's a disintegrator gun.",

# "What's that?",

# "I read about it in the books from Beforethewars. Mostly people with",
# "space-ships have disintegrator guns. They point them at you and you get",
# "disintegratored.",

# "They didn't point it at us till now, pointed out Red with his heart",
# "not quite in it.",

# "I don't care. I'm not hanging around here and getting disintegratored.",
# "I'm getting my father.",

# "Cowardy-cat. Yellow cowardy-cat.",

# "I don't care. You can call all the names you want, but if you bother",
# "them now you'll get disintegratored. You wait and see, and it'll be all",
# "your fault.",

# "He made for the narrow spiral stairs that led to the main floor of the",
# "barn, stopped at its head, then backed away.",

# "Red's mother was moving up, panting a little with the exertion and",
# "smiling a tight smile for the benefit of Slim in his capacity as guest.",

# "Red! You, Red! Are you up there? Now don't try to hide. I know this is",
# "where you're keeping them. Cook saw where you ran with the meat.",

# "Red quavered, Hello, ma!",

# "Now show me those nasty animals? I'm going to see to it that you get",
# "rid of them right away.",

# "It was over! And despite the imminent corporal punishment, Red felt",
# "something like a load fall from him. At least the decision was out of",
# "his hands.",

# "Right there, ma. I didn't do anything to them, ma. I didn't know. They",
# "just looked like little animals and I thought you'd let me keep them,",
# "ma. I wouldn't have taken the meat only they wouldn't eat grass or",
# "leaves and we couldn't find good nuts or berries and cook never lets me",
# "have anything or I would have asked her and I didn't know it was for",
# "lunch and--",

# "He was speaking on the sheer momentum of terror and did not realize that",
# "his mother did not hear him but, with eyes frozen and popping at the",
# "cage, was screaming in thin, piercing tones.",

# "",
# "X",

# "The Astronomer was saying, A quiet burial is all we can do. There is no",
# "point in any publicity now, when they heard the screams.",

# "She had not entirely recovered by the time she reached them, running and",
# "running. It was minutes before her husband could extract sense from her.",

# "She was saying, finally, I tell you they're in the barn. I don't know",
# "what they are. No, no--",

# "She barred the Industrialist's quick movement in that direction. She",
# "said, Don't _you_ go. Send one of the hands with a shotgun. I tell you",
# "I never saw anything like it. Little horrible beasts with--with--I can't",
# "describe it. To think that Red was touching them and trying to feed",
# "them. He was _holding_ them, and feeding them meat.",

# "Red began, I only--",

# "And Slim said, It was not--",

# "The Industrialist said, quickly, Now you boys have done enough harm",
# "today. March! Into the house! And not a word; not one word! I'm not",
# "interested in anything you have to say. After this is all over, I'll",
# "hear you out and as for you, Red, I'll see that you're properly",
# "punished.",

# "He turned to his wife. Now whatever the animals are, we'll have them",
# "killed. He added quietly once the youngsters were out of hearing,",
# "Come, come. The children aren't hurt and, after all, they haven't done",
# "anything really terrible. They've just found a new pet.",

# "The Astronomer spoke with difficulty. Pardon me, ma'am, but can you",
# "describe these animals?",

# "She shook her head. She was quite beyond words.",

# "Can you just tell me if they--",

# "I'm sorry, said the Industrialist, apologetically, but I think I had",
# "better take care of her. Will you excuse me?",

# "A moment. Please. One moment. She said she had never seen such animals",
# "before. Surely it is not usual to find animals that are completely",
# "unique on an estate such as this.",

# "I'm sorry. Let's not discuss that now.",

# "Except that unique animals might have landed during the night.",

# "The Industrialist stepped away from his wife. What are you implying?",

# "I think we had better go to the barn, sir!",

# "The Industrialist stared a moment, turned and suddenly and quite",
# "uncharacteristically began running. The Astronomer followed and the",
# "woman's wail rose unheeded behind them.",

# "",
# "XI",

# "The Industrialist stared, looked at the Astronomer, turned to stare",
# "again.",

# "Those?",

# "Those, said the Astronomer. I have no doubt we appear strange and",
# "repulsive to them.",

# "What do they say?",

# "Why, that they are uncomfortable and tired and even a little sick, but",
# "that they are not seriously damaged, and that the youngsters treated",
# "them well.",

# "Treated them well! Scooping them up, keeping them in a cage, giving",
# "them grass and raw meat to eat? Tell me how to speak to them.",

# "It may take a little time. Think _at_ them. Try to listen. It will come",
# "to you, but perhaps not right away.",

# "The Industrialist tried. He grimaced with the effort of it, thinking",
# "over and over again, The youngsters were ignorant of your identity.",

# "And the thought was suddenly in his mind: We were quite aware of it and",
# "because we knew they meant well by us according to their own view of the",
# "matter, we did not attempt to attack them.",

# "Attack them? thought the Industrialist, and said it aloud in his",
# "concentration.",

# "Why, yes, came the answering thought. We are armed.",

# "One of the revolting little creatures in the cage lifted a metal object",
# "and there was a sudden hole in the top of the cage and another in the",
# "roof of the barn, each hole rimmed with charred wood.",

# "We hope, the creatures thought, it will not be too difficult to make",
# "repairs.",

# "The Industrialist found it impossible to organize himself to the point",
# "of directed thought. He turned to the Astronomer. And with that weapon",
# "in their possession they let themselves be handled and caged? I don't",
# "understand it.",

# "But the calm thought came, We would not harm the young of an",
# "intelligent species.",

# "",
# "XII",

# "It was twilight. The Industrialist had entirely missed the evening meal",
# "and remained unaware of the fact.",

# "He said, Do you really think the ship will fly?",

# "If they say so, said the Astronomer, I'm sure it will. They'll be",
# "back, I hope, before too long.",

# "And when they do, said the Industrialist, energetically, I will keep",
# "my part of the agreement. What is more I will move sky and earth to have",
# "the world accept them. I was entirely wrong, Doctor. Creatures that",
# "would refuse to harm children, under such provocation as they received,",
# "are admirable. But you know--I almost hate to say this--",

# "Say what?",

# "The kids. Yours and mine. I'm almost proud of them. Imagine seizing",
# "these creatures, feeding them or trying to, and keeping them hidden. The",
# "amazing gall of it. Red told me it was his idea to get a job in a circus",
# "on the strength of them. Imagine!",

# "The Astronomer said, Youth!",

# "",
# "XIII",

# "The Merchant said, Will we be taking off soon?",

# "Half an hour, said the Explorer.",

# "It was going to be a lonely trip back. All the remaining seventeen of",
# "the crew were dead and their ashes were to be left on a strange planet.",
# "Back they would go with a limping ship and the burden of the controls",
# "entirely on himself.",

# "The Merchant said, It was a good business stroke, not harming the young",
# "ones. We will get very good terms; _very_ good terms.",

# "The Explorer thought: Business!",

# "The Merchant then said, They've lined up to see us off. All of them.",
# "You don't think they're too close, do you? It would be bad to burn any",
# "of them with the rocket blast at this stage of the game.",

# "They're safe.",

# "Horrible-looking things, aren't they?",

# "Pleasant enough, inside. Their thoughts are perfectly friendly.",

# "You wouldn't believe it of them. That immature one, the one that first",
# "picked us up--",

# "They call him Red, provided the Explorer.",

# "That's a queer name for a monster. Makes me laugh. He actually feels",
# "_bad_ that we're leaving. Only I can't make out exactly why. The nearest",
# "I can come to it is something about a lost opportunity with some",
# "organization or other that I can't quite interpret.",

# "A circus, said the Explorer, briefly.",

# "What? Why, the impertinent monstrosity.",

# "Why not? What would you have done if you had found _him_ wandering on",
# "_your_ native world; found him sleeping on a field on Earth, red",
# "tentacles, six legs, pseudopods and all?",

# "",
# "XIV",

# "Red watched the ship leave. His red tentacles, which gave him his",
# "nickname, quivered their regret at lost opportunity to the very last,",
# "and the eyes at their tips filled with drifting yellowish crystals that",
# "were the equivalent of Earthly tears.",

# "",
# "",
# "",
# "Transcriber's Note:",

#     "This etext was produced from _Space Science Fiction_ May 1952.",
#     "Extensive research did not uncover any evidence that the U.S.",
#     "copyright on this publication was renewed. Minor spelling and",
#     "typographical errors have been corrected without note.",

# "",
# "",
# "",
# "",
# "End of the Project Gutenberg EBook of Youth, by Isaac Asimov",

# "*** END OF THIS PROJECT GUTENBERG EBOOK YOUTH ***",

# "***** This file should be named 31547.txt or 31547.zip *****",
# "This and all associated files of various formats will be found in:",
#         "http://www.gutenberg.org/3/1/5/4/31547/",

# "Produced by Greg Weeks, Stephen Blundell and the Online",
# "Distributed Proofreading Team at http://www.pgdp.net",

# "",
# "Updated editions will replace the previous one--the old editions",
# "will be renamed.",

# "Creating the works from public domain print editions means that no",
# "one owns a United States copyright in these works, so the Foundation",
# "(and you!) can copy and distribute it in the United States without",
# "permission and without paying copyright royalties.  Special rules,",
# "set forth in the General Terms of Use part of this license, apply to",
# "copying and distributing Project Gutenberg-tm electronic works to",
# "protect the PROJECT GUTENBERG-tm concept and trademark.  Project",
# "Gutenberg is a registered trademark, and may not be used if you",
# "charge for the eBooks, unless you receive specific permission.  If you",
# "do not charge anything for copies of this eBook, complying with the",
# "rules is very easy.  You may use this eBook for nearly any purpose",
# "such as creation of derivative works, reports, performances and",
# "research.  They may be modified and printed and given away--you may do",
# "practically ANYTHING with public domain eBooks.  Redistribution is",
# "subject to the trademark license, especially commercial",
# "redistribution.",

# "",
# "",
# "*** START: FULL LICENSE ***",

# "THE FULL PROJECT GUTENBERG LICENSE",
# "PLEASE READ THIS BEFORE YOU DISTRIBUTE OR USE THIS WORK",

# "To protect the Project Gutenberg-tm mission of promoting the free",
# "distribution of electronic works, by using or distributing this work",
# "(or any other work associated in any way with the phrase Project",
# "Gutenberg), you agree to comply with all the terms of the Full Project",
# "Gutenberg-tm License (available with this file or online at",
# "http://gutenberg.net/license).",

# "",
# "Section 1.  General Terms of Use and Redistributing Project Gutenberg-tm",
# "electronic works",

# "1.A.  By reading or using any part of this Project Gutenberg-tm",
# "electronic work, you indicate that you have read, understand, agree to",
# "and accept all the terms of this license and intellectual property",
# "(trademark/copyright) agreement.  If you do not agree to abide by all",
# "the terms of this agreement, you must cease using and return or destroy",
# "all copies of Project Gutenberg-tm electronic works in your possession.",
# "If you paid a fee for obtaining a copy of or access to a Project",
# "Gutenberg-tm electronic work and you do not agree to be bound by the",
# "terms of this agreement, you may obtain a refund from the person or",
# "entity to whom you paid the fee as set forth in paragraph 1.E.8.",

# "1.B.  Project Gutenberg is a registered trademark.  It may only be",
# "used on or associated in any way with an electronic work by people who",
# "agree to be bound by the terms of this agreement.  There are a few",
# "things that you can do with most Project Gutenberg-tm electronic works",
# "even without complying with the full terms of this agreement.  See",
# "paragraph 1.C below.  There are a lot of things you can do with Project",
# "Gutenberg-tm electronic works if you follow the terms of this agreement",
# "and help preserve free future access to Project Gutenberg-tm electronic",
# "works.  See paragraph 1.E below.",

# "1.C.  The Project Gutenberg Literary Archive Foundation (the Foundation",
# "or PGLAF), owns a compilation copyright in the collection of Project",
# "Gutenberg-tm electronic works.  Nearly all the individual works in the",
# "collection are in the public domain in the United States.  If an",
# "individual work is in the public domain in the United States and you are",
# "located in the United States, we do not claim a right to prevent you from",
# "copying, distributing, performing, displaying or creating derivative",
# "works based on the work as long as all references to Project Gutenberg",
# "are removed.  Of course, we hope that you will support the Project",
# "Gutenberg-tm mission of promoting free access to electronic works by",
# "freely sharing Project Gutenberg-tm works in compliance with the terms of",
# "this agreement for keeping the Project Gutenberg-tm name associated with",
# "the work.  You can easily comply with the terms of this agreement by",
# "keeping this work in the same format with its attached full Project",
# "Gutenberg-tm License when you share it without charge with others.",

# "1.D.  The copyright laws of the place where you are located also govern",
# "what you can do with this work.  Copyright laws in most countries are in",
# "a constant state of change.  If you are outside the United States, check",
# "the laws of your country in addition to the terms of this agreement",
# "before downloading, copying, displaying, performing, distributing or",
# "creating derivative works based on this work or any other Project",
# "Gutenberg-tm work.  The Foundation makes no representations concerning",
# "the copyright status of any work in any country outside the United",
# "States.",

# "1.E.  Unless you have removed all references to Project Gutenberg:",

# "1.E.1.  The following sentence, with active links to, or other immediate",
# "access to, the full Project Gutenberg-tm License must appear prominently",
# "whenever any copy of a Project Gutenberg-tm work (any work on which the",
# "phrase Project Gutenberg appears, or with which the phrase Project",
# "Gutenberg is associated) is accessed, displayed, performed, viewed,",
# "copied or distributed:",

# "This eBook is for the use of anyone anywhere at no cost and with",
# "almost no restrictions whatsoever.  You may copy it, give it away or",
# "re-use it under the terms of the Project Gutenberg License included",
# "with this eBook or online at www.gutenberg.net",

# "1.E.2.  If an individual Project Gutenberg-tm electronic work is derived",
# "from the public domain (does not contain a notice indicating that it is",
# "posted with permission of the copyright holder), the work can be copied",
# "and distributed to anyone in the United States without paying any fees",
# "or charges.  If you are redistributing or providing access to a work",
# "with the phrase Project Gutenberg associated with or appearing on the",
# "work, you must comply either with the requirements of paragraphs 1.E.1",
# "through 1.E.7 or obtain permission for the use of the work and the",
# "Project Gutenberg-tm trademark as set forth in paragraphs 1.E.8 or",
# "1.E.9.",

# "1.E.3.  If an individual Project Gutenberg-tm electronic work is posted",
# "with the permission of the copyright holder, your use and distribution",
# "must comply with both paragraphs 1.E.1 through 1.E.7 and any additional",
# "terms imposed by the copyright holder.  Additional terms will be linked",
# "to the Project Gutenberg-tm License for all works posted with the",
# "permission of the copyright holder found at the beginning of this work.",

# "1.E.4.  Do not unlink or detach or remove the full Project Gutenberg-tm",
# "License terms from this work, or any files containing a part of this",
# "work or any other work associated with Project Gutenberg-tm.",

# "1.E.5.  Do not copy, display, perform, distribute or redistribute this",
# "electronic work, or any part of this electronic work, without",
# "prominently displaying the sentence set forth in paragraph 1.E.1 with",
# "active links or immediate access to the full terms of the Project",
# "Gutenberg-tm License.",

# "1.E.6.  You may convert to and distribute this work in any binary,",
# "compressed, marked up, nonproprietary or proprietary form, including any",
# "word processing or hypertext form.  However, if you provide access to or",
# "distribute copies of a Project Gutenberg-tm work in a format other than",
# "Plain Vanilla ASCII or other format used in the official version",
# "posted on the official Project Gutenberg-tm web site (www.gutenberg.net),",
# "you must, at no additional cost, fee or expense to the user, provide a",
# "copy, a means of exporting a copy, or a means of obtaining a copy upon",
# "request, of the work in its original Plain Vanilla ASCII or other",
# "form.  Any alternate format must include the full Project Gutenberg-tm",
# "License as specified in paragraph 1.E.1.",

# "1.E.7.  Do not charge a fee for access to, viewing, displaying,",
# "performing, copying or distributing any Project Gutenberg-tm works",
# "unless you comply with paragraph 1.E.8 or 1.E.9.",

# "1.E.8.  You may charge a reasonable fee for copies of or providing",
# "access to or distributing Project Gutenberg-tm electronic works provided",
# "that",

# "- You pay a royalty fee of 20% of the gross profits you derive from",
#      "the use of Project Gutenberg-tm works calculated using the method",
#      "you already use to calculate your applicable taxes.  The fee is",
#      "owed to the owner of the Project Gutenberg-tm trademark, but he",
#      "has agreed to donate royalties under this paragraph to the",
#      "Project Gutenberg Literary Archive Foundation.  Royalty payments",
#      "must be paid within 60 days following each date on which you",
#      "prepare (or are legally required to prepare) your periodic tax",
#      "returns.  Royalty payments should be clearly marked as such and",
#      "sent to the Project Gutenberg Literary Archive Foundation at the",
#      "address specified in Section 4, Information about donations to",
#      "the Project Gutenberg Literary Archive Foundation.",

# "- You provide a full refund of any money paid by a user who notifies",
#      "you in writing (or by e-mail) within 30 days of receipt that s/he",
#      "does not agree to the terms of the full Project Gutenberg-tm",
#      "License.  You must require such a user to return or",
#      "destroy all copies of the works possessed in a physical medium",
#      "and discontinue all use of and all access to other copies of",
#      "Project Gutenberg-tm works.",

# "- You provide, in accordance with paragraph 1.F.3, a full refund of any",
#      "money paid for a work or a replacement copy, if a defect in the",
#      "electronic work is discovered and reported to you within 90 days",
#      "of receipt of the work.",

# "- You comply with all other terms of this agreement for free",
#      "distribution of Project Gutenberg-tm works.",

# "1.E.9.  If you wish to charge a fee or distribute a Project Gutenberg-tm",
# "electronic work or group of works on different terms than are set",
# "forth in this agreement, you must obtain permission in writing from",
# "both the Project Gutenberg Literary Archive Foundation and Michael",
# "Hart, the owner of the Project Gutenberg-tm trademark.  Contact the",
# "Foundation as set forth in Section 3 below.",

# "1.F.",

# "1.F.1.  Project Gutenberg volunteers and employees expend considerable",
# "effort to identify, do copyright research on, transcribe and proofread",
# "public domain works in creating the Project Gutenberg-tm",
# "collection.  Despite these efforts, Project Gutenberg-tm electronic",
# "works, and the medium on which they may be stored, may contain",
# "Defects, such as, but not limited to, incomplete, inaccurate or",
# "corrupt data, transcription errors, a copyright or other intellectual",
# "property infringement, a defective or damaged disk or other medium, a",
# "computer virus, or computer codes that damage or cannot be read by",
# "your equipment.",

# "1.F.2.  LIMITED WARRANTY, DISCLAIMER OF DAMAGES - Except for the Right",
# "of Replacement or Refund described in paragraph 1.F.3, the Project",
# "Gutenberg Literary Archive Foundation, the owner of the Project",
# "Gutenberg-tm trademark, and any other party distributing a Project",
# "Gutenberg-tm electronic work under this agreement, disclaim all",
# "liability to you for damages, costs and expenses, including legal",
# "fees.  YOU AGREE THAT YOU HAVE NO REMEDIES FOR NEGLIGENCE, STRICT",
# "LIABILITY, BREACH OF WARRANTY OR BREACH OF CONTRACT EXCEPT THOSE",
# "PROVIDED IN PARAGRAPH F3.  YOU AGREE THAT THE FOUNDATION, THE",
# "TRADEMARK OWNER, AND ANY DISTRIBUTOR UNDER THIS AGREEMENT WILL NOT BE",
# "LIABLE TO YOU FOR ACTUAL, DIRECT, INDIRECT, CONSEQUENTIAL, PUNITIVE OR",
# "INCIDENTAL DAMAGES EVEN IF YOU GIVE NOTICE OF THE POSSIBILITY OF SUCH",
# "DAMAGE.",

# "1.F.3.  LIMITED RIGHT OF REPLACEMENT OR REFUND - If you discover a",
# "defect in this electronic work within 90 days of receiving it, you can",
# "receive a refund of the money (if any) you paid for it by sending a",
# "written explanation to the person you received the work from.  If you",
# "received the work on a physical medium, you must return the medium with",
# "your written explanation.  The person or entity that provided you with",
# "the defective work may elect to provide a replacement copy in lieu of a",
# "refund.  If you received the work electronically, the person or entity",
# "providing it to you may choose to give you a second opportunity to",
# "receive the work electronically in lieu of a refund.  If the second copy",
# "is also defective, you may demand a refund in writing without further",
# "opportunities to fix the problem.",

# "1.F.4.  Except for the limited right of replacement or refund set forth",
# "in paragraph 1.F.3, this work is provided to you 'AS-IS' WITH NO OTHER",
# "WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO",
# "WARRANTIES OF MERCHANTIBILITY OR FITNESS FOR ANY PURPOSE.",

# "1.F.5.  Some states do not allow disclaimers of certain implied",
# "warranties or the exclusion or limitation of certain types of damages.",
# "If any disclaimer or limitation set forth in this agreement violates the",
# "law of the state applicable to this agreement, the agreement shall be",
# "interpreted to make the maximum disclaimer or limitation permitted by",
# "the applicable state law.  The invalidity or unenforceability of any",
# "provision of this agreement shall not void the remaining provisions.",

# "1.F.6.  INDEMNITY - You agree to indemnify and hold the Foundation, the",
# "trademark owner, any agent or employee of the Foundation, anyone",
# "providing copies of Project Gutenberg-tm electronic works in accordance",
# "with this agreement, and any volunteers associated with the production,",
# "promotion and distribution of Project Gutenberg-tm electronic works,",
# "harmless from all liability, costs and expenses, including legal fees,",
# "that arise directly or indirectly from any of the following which you do",
# "or cause to occur: (a) distribution of this or any Project Gutenberg-tm",
# "work, (b) alteration, modification, or additions or deletions to any",
# "Project Gutenberg-tm work, and (c) any Defect you cause.",

# "",
# "Section  2.  Information about the Mission of Project Gutenberg-tm",

# "Project Gutenberg-tm is synonymous with the free distribution of",
# "electronic works in formats readable by the widest variety of computers",
# "including obsolete, old, middle-aged and new computers.  It exists",
# "because of the efforts of hundreds of volunteers and donations from",
# "people in all walks of life.",

# "Volunteers and financial support to provide volunteers with the",
# "assistance they need are critical to reaching Project Gutenberg-tm's",
# "goals and ensuring that the Project Gutenberg-tm collection will",
# "remain freely available for generations to come.  In 2001, the Project",
# "Gutenberg Literary Archive Foundation was created to provide a secure",
# "and permanent future for Project Gutenberg-tm and future generations.",
# "To learn more about the Project Gutenberg Literary Archive Foundation",
# "and how your efforts and donations can help, see Sections 3 and 4",
# "and the Foundation web page at http://www.pglaf.org.",

# "",
# "Section 3.  Information about the Project Gutenberg Literary Archive",
# "Foundation",

# "The Project Gutenberg Literary Archive Foundation is a non profit",
# "501(c)(3) educational corporation organized under the laws of the",
# "state of Mississippi and granted tax exempt status by the Internal",
# "Revenue Service.  The Foundation's EIN or federal tax identification",
# "number is 64-6221541.  Its 501(c)(3) letter is posted at",
# "http://pglaf.org/fundraising.  Contributions to the Project Gutenberg",
# "Literary Archive Foundation are tax deductible to the full extent",
# "permitted by U.S. federal laws and your state's laws.",

# "The Foundation's principal office is located at 4557 Melan Dr. S.",
# "Fairbanks, AK, 99712., but its volunteers and employees are scattered",
# "throughout numerous locations.  Its business office is located at",
# "809 North 1500 West, Salt Lake City, UT 84116, (801) 596-1887, email",
# "business@pglaf.org.  Email contact links and up to date contact",
# "information can be found at the Foundation's web site and official",
# "page at http://pglaf.org",

# "For additional contact information:",
#      "Dr. Gregory B. Newby",
#      "Chief Executive and Director",
#      "gbnewby@pglaf.org",

# "",
# "Section 4.  Information about Donations to the Project Gutenberg",
# "Literary Archive Foundation",

# "Project Gutenberg-tm depends upon and cannot survive without wide",
# "spread public support and donations to carry out its mission of",
# "increasing the number of public domain and licensed works that can be",
# "freely distributed in machine readable form accessible by the widest",
# "array of equipment including outdated equipment.  Many small donations",
# "($1 to $5,000) are particularly important to maintaining tax exempt",
# "status with the IRS.",

# "The Foundation is committed to complying with the laws regulating",
# "charities and charitable donations in all 50 states of the United",
# "States.  Compliance requirements are not uniform and it takes a",
# "considerable effort, much paperwork and many fees to meet and keep up",
# "with these requirements.  We do not solicit donations in locations",
# "where we have not received written confirmation of compliance.  To",
# "SEND DONATIONS or determine the status of compliance for any",
# "particular state visit http://pglaf.org",

# "While we cannot and do not solicit contributions from states where we",
# "have not met the solicitation requirements, we know of no prohibition",
# "against accepting unsolicited donations from donors in such states who",
# "approach us with offers to donate.",

# "International donations are gratefully accepted, but we cannot make",
# "any statements concerning tax treatment of donations received from",
# "outside the United States.  U.S. laws alone swamp our small staff.",

# "Please check the Project Gutenberg Web pages for current donation",
# "methods and addresses.  Donations are accepted in a number of other",
# "ways including including checks, online payments and credit card",
# "donations.  To donate, please visit: http://pglaf.org/donate",

# "",
# "Section 5.  General Information About Project Gutenberg-tm electronic",
# "works.",

# "Professor Michael S. Hart is the originator of the Project Gutenberg-tm",
# "concept of a library of electronic works that could be freely shared",
# "with anyone.  For thirty years, he produced and distributed Project",
# "Gutenberg-tm eBooks with only a loose network of volunteer support.",

# "",
# "Project Gutenberg-tm eBooks are often created from several printed",
# "editions, all of which are confirmed as Public Domain in the U.S.",
# "unless a copyright notice is included.  Thus, we do not necessarily",
# "keep eBooks in compliance with any particular paper edition.",

# "",
# "Most people start at our Web site which has the main PG search facility:",

#      "http://www.gutenberg.net",

# "This Web site includes information about Project Gutenberg-tm,",
# "including how to make donations to the Project Gutenberg Literary",
# "Archive Foundation, how to help produce our new eBooks, and how to",
# "subscribe to our email newsletter to hear about new eBooks.",
# ]