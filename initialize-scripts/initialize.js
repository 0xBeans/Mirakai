// mirakaiDnaParser, 0xa7d949e4562c4f9c5156282dc85fc40b9460e007
// mirakaiScrollsRenderer, 0xf0087121fc3164639083c3f3c3fc3d5587429f3d
// orbsToken, 0xca6a720ac282e8634f595c4351b827191aea1bbe
// mirakaiHeroesRenderer, 0xf55e118dc257dde3611d0f9c3ff85ac981c54f95
// mirakaiScrolls, 0xd186db306f8bbdd515663e3880b2a94c16fa58b2
// mirakaiHeroes, 0xd1e1060ae2c082d10ae5282d640873444bdadde1
const fs = require("fs");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Initializing contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // todo: Update the addresses to attach to after deploy
  const MirakaiDnaParser = await ethers.getContractFactory("MirakaiDnaParser");
  const mirakaiDnaParser = await MirakaiDnaParser.attach("0xa7d949e4562c4f9c5156282dc85fc40b9460e007");

  const MirakaiScrollsRenderer = await ethers.getContractFactory("MirakaiScrollsRenderer");
  const mirakaiScrollsRenderer = await MirakaiScrollsRenderer.attach("0xf0087121fc3164639083c3f3c3fc3d5587429f3d");

  // read base64 encoded font
  const file = await fs.readFileSync(
    __dirname + '/silkscreen-op2.txt'
  );

  const content = file.toString();
  
  // font file is < 24KB and can be set in a single txn in contract storage
  let setFontTxn = await mirakaiScrollsRenderer.saveFile(0, content);

  console.log('setFontTxn', setFontTxn);

  // These values will change to real weights and traits when we deploy to mainnet
  const traitsAndWeights = [
    {
      index: 0,
      traitNames: [
        "clan arcadia",
        "clan berra",
        "clan zirconia",
        "clan zephyr",
        "clan aite",
      ],
      traitWeights: [2000, 2000, 2000, 2000, 2000],
    },
    {
      index: 1,
      traitNames: ["dawn genus", "dusk genus", "light genus", "midnight genus"],
      traitWeights: [5434, 1783, 1783, 1000],
    },
    {
      index: 2,
      traitNames: [
        "80's hair", // 0
        "angel's guard",
        "angel's cap",
        "bamboo hat",
        "beanie",
        "black bucket hat",
        "blit amai hat",
        "blitnaut helmet",
        "blit sprout head",
        "blue bandana",
        "bowl", // 10
        "gas mask",
        "backwards cap",
        "forwards cap",
        "cat mask",
        "chaos feather",
        "emo hair",
        "devil horns",
        "diamond crown",
        "driving cap",
        "forbidden helmet", // 20
        "fox mask (side)",
        "goblin mask",
        "gold crown",
        "gold face shield",
        "gold headgear",
        "angel halo",
        "hard hat",
        "devil's helmet",
        "hyperloot crown",
        "punk hair", // 30
        "infinity crown",
        "knight helmet",
        "lion's mane",
        "gold hair",
        "ski mask",
        "mage hat",
        "hermes cap",
        "ninja headband",
        "orchid crown",
        "flower slide", // 40
        "paper boat hat",
        "plat. face shield",
        "plat. headgear",
        "purple bucket hat",
        "raven feather",
        "slime hat",
        "gold spikey hair",
        "slicked-back hair",
        "black hairbun",
        "black hair", // 50
        "black hair (2)",
        "samurai bun",
        "black spikey hair",
        "black buzzcut",
        "cool black hair",
        "teddy hat",
        "skater hair",
        "tiara",
        "tophat",
        "von's helmet", // 60
        "cool gold hair",
        "white bandana",
        "white bucket hat",
        "fox mask",
        "zinias helmet",
        "masquerade",
        "kaiju cap",
        "phantom mask",
      ],
      traitWeights: [
        200, 80, 100, 200, 200, 200, 40, 90, 90, 200, 200, 90, 200, 200, 90, 40,
        200, 90, 60, 200, 60, 90, 90, 40, 40, 90, 200, 200, 180, 90, 180, 40, 180,
        180, 180, 90, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180,
        180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 180, 90, 180, 180,
        180, 40, 40, 90, 90, 90,
      ],
    },
    {
      index: 3,
      traitNames: [
        "white eyes",
        "annoyed eyes",
        "black eyes",
        "blue eyes",
        "brown eyes",
        "chromia eyes",
        "green eyes",
        "red eyes",
        "gold eyes",
        "glasses",
        "sly eyes",
        "over9000 lens",
        "eyepatch",
        "shadow eyes",
        "happy eyes",
        "sunglasses",
        "ghsxt eye",
      ],
      traitWeights: [
        100, 900, 900, 900, 1200, 100, 1000, 1000, 100, 1000, 400, 100, 400, 100,
        1000, 400, 400,
      ],
    },
    {
      index: 4,
      traitNames: [
        "blitmap jess",
        "broker lips",
        "bucktooth",
        "cute",
        "buck-surprised",
        "smiling",
        "neutral",
        "chewing",
        "smirk",
        "surprised",
        "terrified",
        "tongue",
        "toothpick",
        "upset",
        "kissy",
      ],
      traitWeights: [
        230, 80, 230, 900, 900, 900, 900, 900, 900, 900, 900, 230, 230, 900, 900,
      ],
    },
    {
      index: 5,
      traitNames: [
        "angel wings",
        "angels gown",
        "apron",
        "battle suit",
        "black hoodie",
        "blackhat top",
        "blue hoodie",
        "buttonup",
        "chaos cape",
        "yeezy",
        "dark angel wings",
        "elemental armour",
        "elysian robe",
        "lost realm fur",
        "grey hoodie",
        "jersey",
        "karate gi",
        "kimono",
        "leather jacket",
        "letterman",
        "long shirt",
        "mage robe",
        "ninja suit",
        "noble robe",
        "yeezy tank",
        "pj's",
        "tracksuit",
        "wisdom robe",
        "robot suit",
        "sacred hakama",
        "vaporjacket",
        "shirtless",
        "silver armour",
        "formal suit",
        "superstar top",
        "floaty",
        "sashed toga",
        "toga",
        "trenchoat",
        "t-shirt",
        "von's viking coat",
        "white hoodie",
        "white tank top",
        "zinias cape",
        "hulk top",
        "bandit top",
      ],
      traitWeights: [
        50, 50, 280, 280, 280, 280, 280, 280, 50, 280, 50, 50, 50, 50, 290, 290,
        290, 290, 280, 280, 280, 200, 280, 50, 280, 280, 280, 50, 280, 50, 280,
        280, 280, 280, 280, 280, 280, 280, 280, 280, 50, 200, 280, 50, 280, 280,
      ],
    },
    {
      index: 6,
      traitNames: [
        "apron",
        "battle suit",
        "black joggers",
        "blackhat",
        "blue joggers",
        "chaos cape",
        "cowboy pants",
        "elemental armour",
        "lost realm fur",
        "future trousers",
        "grey joggers",
        "jeans",
        "sports pants",
        "karate gi",
        "kimono",
        "mage robe",
        "ninja suit",
        "noble robe",
        "pantless",
        "pj's",
        "pleats",
        "cute underwear",
        "tracksuit",
        "robot suit",
        "sacred hakama",
        "silver armour",
        "striped pants",
        "formal suit",
        "floaty",
        "toga",
        "white joggers",
        "wraslin",
      ],
      traitWeights: [
        374, 374, 374, 374, 374, 80, 374, 80, 80, 374, 374, 374, 374, 360, 360,
        360, 360, 80, 360, 360, 360, 100, 360, 360, 80, 360, 360, 360, 360, 360,
        360, 360,
      ],
    },
    {
      index: 7,
      traitNames: [
        "1000 y/o cane",
        "100 y/o cane",
        "axe",
        "4 leaf clover",
        "angel blades",
        "angel wand",
        "big daddy",
        "bone",
        "butcher knife",
        "caveman club",
        "chain",
        "chaos axe",
        "chaos blade",
        "chaos spellbook",
        "crossbow",
        "cursed arm",
        "cursed feather",
        "cursed lasso",
        "diamond sword",
        "divine bow",
        "doom sword",
        "dual axes",
        "elemental wand",
        "fairy wand",
        "fist of hanobi",
        "fist of tubby",
        "flameblade",
        "forgotten sword",
        "giant shield",
        "giant",
        "golden bow",
        "golden knuckles",
        "kinky chains",
        "sub of doom",
        "icy scythe",
        "icicle",
        "infinity shield",
        "iron fist",
        "golden katana",
        "katana",
        "kunai",
        "lightning",
        "mace",
        "magic wand",
        "molotov",
        "monofilament",
        "wand of torment",
        "necronomicon",
        "golden nunchaku",
        "nunchaku",
        "possessed sword",
        "royal claw",
        "sacred beanstock",
        "sacred spear",
        "scimitar",
        "serpent staff",
        "short sword",
        "sledge",
        "spiked bat",
        "wizard wand",
        "big sunflower",
        "flame spear",
        "sun spear",
        "swift claw",
        "tablet",
        "tekko kagi",
        "tiny board",
        "big oofer",
        "twin spears",
        "vine claw",
        "punished wand",
        "mana bottle",
        "knowledge staff",
        "enlightened staff",
        "wodden bow",
        "wooden shield",
        "wrench",
        "zinias sword",
        "gold tekko kagi",
        "shields shield",
        "weaponless",
      ],
      traitWeights: [
        100, 150, 150, 150, 90, 90, 140, 140, 140, 140, 140, 90, 90, 90, 140, 90,
        90, 90, 90, 90, 140, 90, 90, 120, 100, 100, 140, 140, 150, 90, 150, 150,
        150, 150, 150, 150, 90, 150, 90, 150, 150, 90, 150, 150, 90, 100, 150, 90,
        90, 150, 90, 100, 90, 100, 130, 130, 130, 130, 130, 130, 150, 130, 130,
        130, 150, 150, 150, 150, 150, 150, 150, 90, 90, 100, 150, 150, 150, 90,
        90, 150, 150,
      ],
    },
    {
      index: 8,
      traitNames: [
        "markless",
        "bandaid",
        "gem",
        "blush",
        "bold",
        "charcoal",
        "comma",
        "curse mark",
        "cute mole",
        "red marks",
        "eyescar",
        "orange freckles",
        "pink freckles",
        "inverse",
        "pink nose",
        "sunburn",
        "x scar",
      ],
      traitWeights: [
        8450, 100, 100, 100, 50, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
        100, 100,
      ],
    },
    {
      index: 9,
      traitNames: [
        "no cc0",
        "chain runners",
        "blitmap",
        "nouns",
        "mfers",
        "cryptoadz",
        "anonymice",
        "goblintown",
      ],
      traitWeights: [9993, 1, 1, 1, 1, 1, 1, 1], // cc0 is no cc0 trait, all cc0 traits are set with different logic and are rare
    },
  ];

  // set weights and traits in 3 txns
  let firstTxn = await mirakaiDnaParser.setTraitsAndWeights(traitsAndWeights.slice(0, 3));
  let secondTxn = await mirakaiDnaParser.setTraitsAndWeights(traitsAndWeights.slice(3, 5));
  let thirdTxn = await mirakaiDnaParser.setTraitsAndWeights(traitsAndWeights.slice(5));

  console.log('firstTxn', firstTxn);
  console.log('secondTxn', secondTxn);
  console.log('thirdTxn', thirdTxn);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
