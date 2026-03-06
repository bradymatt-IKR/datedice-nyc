export const WMO = {
  0: { l: "Clear Sky", i: "☀️" },
  1: { l: "Mainly Clear", i: "🌤" },
  2: { l: "Partly Cloudy", i: "⛅" },
  3: { l: "Overcast", i: "☁️" },
  45: { l: "Fog", i: "🌫" },
  48: { l: "Freezing Fog", i: "🌫" },
  51: { l: "Light Drizzle", i: "🌦" },
  53: { l: "Drizzle", i: "🌧" },
  55: { l: "Heavy Drizzle", i: "🌧" },
  56: { l: "Freezing Drizzle", i: "🌧" },
  57: { l: "Heavy Freezing Drizzle", i: "🌧" },
  61: { l: "Light Rain", i: "🌧" },
  63: { l: "Moderate Rain", i: "🌧" },
  65: { l: "Heavy Rain", i: "🌧️" },
  66: { l: "Freezing Rain", i: "🌧" },
  67: { l: "Heavy Freezing Rain", i: "🌧" },
  71: { l: "Light Snow", i: "🌨" },
  73: { l: "Moderate Snow", i: "❄️" },
  75: { l: "Heavy Snow", i: "❄️" },
  77: { l: "Snow Grains", i: "❄️" },
  80: { l: "Light Showers", i: "🌦" },
  81: { l: "Moderate Showers", i: "🌧" },
  82: { l: "Violent Showers", i: "⛈" },
  85: { l: "Light Snow Showers", i: "🌨" },
  86: { l: "Heavy Snow Showers", i: "❄️" },
  95: { l: "Thunderstorm", i: "⛈" },
  96: { l: "Thunderstorm w/ Hail", i: "⛈" },
  99: { l: "Severe Thunderstorm", i: "⛈" },
};

export function classifyWeather(tempF, code, humidity, wind) {
  if ([95, 96, 99].includes(code)) return "Stormy";
  if ([71, 73, 75, 77, 85, 86].includes(code)) return "Snowy";
  if ([51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82].includes(code)) return "Rainy";
  if ([45, 48].includes(code)) return "Foggy";
  if (tempF <= 25) return "Frigid";
  if (tempF <= 40) return "Cold";
  if (tempF >= 90) return "Hot";
  if (wind >= 25) return "Windy";
  if (code <= 1 && tempF >= 65) return "Sunny";
  if (code <= 1) return "Mild";
  if (code === 2) return "Partly Cloudy";
  if (code === 3) return "Cloudy";
  return tempF >= 65 ? "Sunny" : "Mild";
}

export function weatherToFilter(c) {
  const map = {
    Sunny: "Sunny", Hot: "Hot", Mild: "Sunny", "Partly Cloudy": "Cloudy",
    Cloudy: "Cloudy", Windy: "Windy", Foggy: "Cloudy", Rainy: "Rainy",
    Stormy: "Rainy", Snowy: "Snowy", Cold: "Cold", Frigid: "Cold",
  };
  return map[c] || "Any Weather";
}
