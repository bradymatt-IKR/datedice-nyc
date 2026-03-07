// ── Color Palette ──
export const P = {
  bg: "#0c0c18",
  card: "rgba(255,255,255,0.04)",
  border: "rgba(255,255,255,0.08)",
  gold: "#e8c36a",
  goldDim: "rgba(232,195,106,0.15)",
  goldBright: "#f5d98a",
  text: "#f0ece2",
  textDim: "rgba(240,236,226,0.45)",
  accent: "#c97d4a",
  rose: "#d4727e",
  green: "#6ecf94",
  blue: "#6aafe8",
  grad: "linear-gradient(135deg, #e8c36a, #c97d4a)",
};

export const sans = "'Helvetica Neue','Segoe UI',sans-serif";
export const serif = "'Georgia','Palatino Linotype',serif";
export const display = "'Playfair Display','Georgia','Palatino Linotype',serif";

// ── Neighborhoods ──
export const NEIGHBORHOODS = {
  Brooklyn: ["Carroll Gardens","Cobble Hill","Brooklyn Heights","DUMBO","Park Slope","Prospect Heights","Williamsburg","Greenpoint","Bushwick","Fort Greene","Clinton Hill","Gowanus","Red Hook","Bay Ridge","Bed-Stuy","Boerum Hill","Crown Heights","Sunset Park","Flatbush"],
  Manhattan: ["West Village","East Village","Lower East Side","SoHo","NoHo","Nolita","Chinatown","Little Italy","Tribeca","Chelsea","Hell's Kitchen","Midtown","Flatiron","NoMad","Gramercy","Murray Hill","Upper East Side","Upper West Side","Harlem","Washington Heights","Financial District","East Harlem"],
  Queens: ["Astoria","Long Island City","Flushing","Jackson Heights","Woodside","Sunnyside"],
  Bronx: ["Arthur Avenue","Mott Haven","City Island"],
  "Across the River": ["Hoboken","Jersey City"],
};

// ── Cuisines ──
export const CUISINES = [
  "Italian","Japanese","Mexican","Chinese","Thai","Korean","Indian","French",
  "Vietnamese","Mediterranean","Middle Eastern","Ethiopian","Peruvian","Colombian",
  "Greek","Spanish","American","Southern","BBQ","Seafood","Pizza","Sushi","Ramen",
  "Tacos","Dim Sum","Steakhouse","Farm-to-Table","Vegan","Brunch","Bakery & Pastry",
  "Cocktail Bar","Wine Bar","Beer Garden","Coffee","Dessert","Food Hall","Deli & Sandwich",
];

// ── Activity Types ──
export const ACTIVITY_TYPES = [
  "Outdoors & Nature","Museum & Art","Live Music & Concerts","Comedy",
  "Theater & Performance","Immersive Experience","Sports & Games","Wellness & Spa",
  "Shopping & Markets","Classes & Workshops","Tours & Walks","Day Trip",
  "Nightlife & Dancing","Arcade & Gaming","Film & Cinema","Photography Walk",
  "Boat & Water","Seasonal & Holiday",
];

// ── Filter Definitions ──
export const FILTERS_MAIN = {
  category: { label: "What Type", icon: "🎯", options: ["Food & Drink","Activities","Surprise Me"] },
  timeOfDay: { label: "When", icon: "🕐", options: ["Morning","Afternoon","Evening","Late Night"] },
  weather: { label: "Weather", icon: "🌤", options: ["Sunny","Hot","Cloudy","Rainy","Snowy","Cold","Windy","Any Weather"] },
  vibe: { label: "Vibe", icon: "✨", options: ["Romantic","Adventurous","Chill","Fancy","Quirky"] },
  budget: { label: "Budget", icon: "💰", options: ["Free","Under $50","$50–150","$150–300","Splurge"] },
  duration: { label: "How Long", icon: "⏳", options: ["Quick (1-2 hrs)","Half Day","Full Day","All Night"] },
};

// ── Borough Colors ──
export const BOROUGH_COLORS = {
  Brooklyn: "#d4727e",
  Manhattan: "#e8c36a",
  Queens: "#6aafe8",
  Bronx: "#6ecf94",
  "Across the River": "#c97d4a",
};

// ── Loading Messages ──
export const LOADING_MESSAGES = [
  "Checking the vibe across the boroughs...",
  "Asking the locals for their hot takes...",
  "Scouring secret NYC spots...",
  "Checking what's poppin' tonight...",
  "Canvassing the five boroughs...",
  "Digging through hidden gems...",
  "Peeking behind the velvet ropes...",
  "Scanning rooftops and basements...",
  "Checking the subway for inspiration...",
  "Flipping through NYC's little black book...",
  "Cross-referencing with NYC insiders...",
  "Hunting for the perfect match...",
];

export const LOADING_EMOJI = {
  food: ["🍕", "🍝", "🥡", "🍣", "🥂", "🍷", "🧁", "🍜"],
  activity: ["🎭", "🎨", "🎸", "🏙", "🌉", "🗽", "🎪", "🚶‍♂️"],
  default: ["🎲", "✨", "🗽", "🌃", "🏙", "🎯", "💛", "🌟"],
};

// ── Quick Filter Presets ──
export const FILTER_PRESETS = [
  { label: "Date Night Classic", emoji: "💛", filters: { category: "Surprise Me", vibe: "Romantic", timeOfDay: "Evening", budget: "$50–150" } },
  { label: "Rainy Day Indoor", emoji: "🌧", filters: { category: "Activities", vibe: "Chill", weather: "Rainy" } },
  { label: "Cheap Thrills", emoji: "🤑", filters: { category: "Surprise Me", vibe: "Adventurous", budget: "Under $50" } },
  { label: "Fancy Night Out", emoji: "🥂", filters: { category: "Food & Drink", vibe: "Fancy", budget: "$150–300", timeOfDay: "Evening" } },
];

// ── Dice Dot Positions ──
export const DICE_DOTS = {
  1: [[50,50]],
  2: [[33,33],[67,67]],
  3: [[33,33],[50,50],[67,67]],
  4: [[33,33],[67,33],[33,67],[67,67]],
  5: [[33,33],[67,33],[50,50],[33,67],[67,67]],
  6: [[33,25],[67,25],[33,50],[67,50],[33,75],[67,75]],
};
