// Hardcoded country → states/provinces mapping for the onboarding flow.
//
// Major countries have full state/province lists.
// All others have at least one "General" entry.

class LocationData {
  LocationData._();

  static List<String> get countries => _countryStates.keys.toList()..sort();

  static List<String> getStates(String country) {
    return _countryStates[country] ?? ['General'];
  }

  static String getCountryFlag(String country) {
    switch (country) {
      case 'India': return '🇮🇳';
      case 'United States': return '🇺🇸';
      case 'United Kingdom': return '🇬🇧';
      case 'Canada': return '🇨🇦';
      case 'Australia': return '🇦🇺';
      case 'Germany': return '🇩🇪';
      case 'France': return '🇫🇷';
      case 'Brazil': return '🇧🇷';
      case 'Japan': return '🇯🇵';
      case 'China': return '🇨🇳';
      case 'South Korea': return '🇰🇷';
      case 'Mexico': return '🇲🇽';
      case 'Indonesia': return '🇮🇩';
      case 'Pakistan': return '🇵🇰';
      case 'Bangladesh': return '🇧🇩';
      case 'Nigeria': return '🇳🇬';
      case 'Russia': return '🇷🇺';
      case 'Italy': return '🇮🇹';
      case 'Spain': return '🇪🇸';
      case 'Turkey': return '🇹🇷';
      case 'Saudi Arabia': return '🇸🇦';
      case 'United Arab Emirates': return '🇦🇪';
      case 'South Africa': return '🇿🇦';
      case 'Egypt': return '🇪🇬';
      case 'Thailand': return '🇹🇭';
      case 'Vietnam': return '🇻🇳';
      case 'Philippines': return '🇵🇭';
      case 'Malaysia': return '🇲🇾';
      case 'Singapore': return '🇸🇬';
      case 'New Zealand': return '🇳🇿';
      case 'Ireland': return '🇮🇪';
      case 'Netherlands': return '🇳🇱';
      case 'Belgium': return '🇧🇪';
      case 'Switzerland': return '🇨🇭';
      case 'Austria': return '🇦🇹';
      case 'Poland': return '🇵🇱';
      case 'Sweden': return '🇸🇪';
      case 'Norway': return '🇳🇴';
      case 'Denmark': return '🇩🇰';
      case 'Finland': return '🇫🇮';
      case 'Portugal': return '🇵🇹';
      case 'Greece': return '🇬🇷';
      case 'Argentina': return '🇦🇷';
      case 'Colombia': return '🇨🇴';
      case 'Chile': return '🇨🇱';
      case 'Peru': return '🇵🇪';
      case 'Kenya': return '🇰🇪';
      case 'Ghana': return '🇬🇭';
      case 'Tanzania': return '🇹🇿';
      case 'Ethiopia': return '🇪🇹';
      case 'Nepal': return '🇳🇵';
      case 'Sri Lanka': return '🇱🇰';
      case 'Myanmar': return '🇲🇲';
      case 'Cambodia': return '🇰🇭';
      case 'Israel': return '🇮🇱';
      case 'Jordan': return '🇯🇴';
      case 'Qatar': return '🇶🇦';
      case 'Kuwait': return '🇰🇼';
      case 'Bahrain': return '🇧🇭';
      case 'Oman': return '🇴🇲';
      case 'Iraq': return '🇮🇶';
      case 'Iran': return '🇮🇷';
      case 'Afghanistan': return '🇦🇫';
      case 'Ukraine': return '🇺🇦';
      case 'Romania': return '🇷🇴';
      case 'Czech Republic': return '🇨🇿';
      case 'Hungary': return '🇭🇺';
      case 'Croatia': return '🇭🇷';
      case 'Serbia': return '🇷🇸';
      case 'Bulgaria': return '🇧🇬';
      case 'Slovakia': return '🇸🇰';
      case 'Slovenia': return '🇸🇮';
      case 'Lithuania': return '🇱🇹';
      case 'Latvia': return '🇱🇻';
      case 'Estonia': return '🇪🇪';
      case 'Iceland': return '🇮🇸';
      case 'Luxembourg': return '🇱🇺';
      case 'Malta': return '🇲🇹';
      case 'Cyprus': return '🇨🇾';
      case 'Morocco': return '🇲🇦';
      case 'Tunisia': return '🇹🇳';
      case 'Algeria': return '🇩🇿';
      case 'Libya': return '🇱🇾';
      case 'Cuba': return '🇨🇺';
      case 'Jamaica': return '🇯🇲';
      case 'Trinidad and Tobago': return '🇹🇹';
      case 'Costa Rica': return '🇨🇷';
      case 'Panama': return '🇵🇦';
      case 'Ecuador': return '🇪🇨';
      case 'Venezuela': return '🇻🇪';
      case 'Uruguay': return '🇺🇾';
      case 'Paraguay': return '🇵🇾';
      case 'Bolivia': return '🇧🇴';
      case 'Honduras': return '🇭🇳';
      case 'Guatemala': return '🇬🇹';
      case 'El Salvador': return '🇸🇻';
      case 'Nicaragua': return '🇳🇮';
      case 'Dominican Republic': return '🇩🇴';
      case 'Haiti': return '🇭🇹';
      case 'Mongolia': return '🇲🇳';
      case 'Uzbekistan': return '🇺🇿';
      case 'Kazakhstan': return '🇰🇿';
      case 'Turkmenistan': return '🇹🇲';
      case 'Kyrgyzstan': return '🇰🇬';
      case 'Tajikistan': return '🇹🇯';
      case 'Georgia': return '🇬🇪';
      case 'Armenia': return '🇦🇲';
      case 'Azerbaijan': return '🇦🇿';
      case 'Fiji': return '🇫🇯';
      case 'Papua New Guinea': return '🇵🇬';
      case 'Maldives': return '🇲🇻';
      case 'Bhutan': return '🇧🇹';
      case 'Brunei': return '🇧🇳';
      case 'Laos': return '🇱🇦';
      case 'Timor-Leste': return '🇹🇱';
      default: return '🏳️';
    }
  }

  static const Map<String, List<String>> _countryStates = {
    // ── Major Countries ─────────────────────────────────────────
    'India': [
      'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar',
      'Chhattisgarh', 'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh',
      'Jharkhand', 'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra',
      'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab',
      'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
      'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
      'Delhi', 'Jammu & Kashmir', 'Ladakh', 'Chandigarh', 'Puducherry',
    ],
    'United States': [
      'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado',
      'Connecticut', 'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho',
      'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana',
      'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota',
      'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada',
      'New Hampshire', 'New Jersey', 'New Mexico', 'New York',
      'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon',
      'Pennsylvania', 'Rhode Island', 'South Carolina', 'South Dakota',
      'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington',
      'West Virginia', 'Wisconsin', 'Wyoming', 'District of Columbia',
    ],
    'United Kingdom': [
      'England', 'Scotland', 'Wales', 'Northern Ireland',
    ],
    'Canada': [
      'Alberta', 'British Columbia', 'Manitoba', 'New Brunswick',
      'Newfoundland and Labrador', 'Nova Scotia', 'Ontario',
      'Prince Edward Island', 'Quebec', 'Saskatchewan',
      'Northwest Territories', 'Nunavut', 'Yukon',
    ],
    'Australia': [
      'New South Wales', 'Victoria', 'Queensland', 'South Australia',
      'Western Australia', 'Tasmania', 'Northern Territory',
      'Australian Capital Territory',
    ],
    'Germany': [
      'Baden-Württemberg', 'Bavaria', 'Berlin', 'Brandenburg', 'Bremen',
      'Hamburg', 'Hesse', 'Lower Saxony', 'Mecklenburg-Vorpommern',
      'North Rhine-Westphalia', 'Rhineland-Palatinate', 'Saarland',
      'Saxony', 'Saxony-Anhalt', 'Schleswig-Holstein', 'Thuringia',
    ],
    'France': [
      'Île-de-France', 'Auvergne-Rhône-Alpes', 'Nouvelle-Aquitaine',
      'Occitanie', 'Hauts-de-France', 'Provence-Alpes-Côte d\'Azur',
      'Grand Est', 'Pays de la Loire', 'Bretagne', 'Normandie',
      'Bourgogne-Franche-Comté', 'Centre-Val de Loire', 'Corse',
    ],
    'Brazil': [
      'São Paulo', 'Rio de Janeiro', 'Minas Gerais', 'Bahia', 'Paraná',
      'Rio Grande do Sul', 'Pernambuco', 'Ceará', 'Pará', 'Maranhão',
      'Santa Catarina', 'Goiás', 'Amazonas', 'Espírito Santo',
      'Paraíba', 'Mato Grosso', 'Distrito Federal', 'Other',
    ],
    'Japan': [
      'Tokyo', 'Osaka', 'Kanagawa', 'Aichi', 'Hokkaido', 'Fukuoka',
      'Saitama', 'Chiba', 'Hyogo', 'Kyoto', 'Hiroshima', 'Other',
    ],
    'China': [
      'Beijing', 'Shanghai', 'Guangdong', 'Zhejiang', 'Jiangsu',
      'Sichuan', 'Shandong', 'Fujian', 'Hubei', 'Henan',
      'Hunan', 'Hebei', 'Liaoning', 'Other',
    ],
    'South Korea': [
      'Seoul', 'Busan', 'Incheon', 'Daegu', 'Daejeon', 'Gwangju',
      'Gyeonggi', 'Gangwon', 'Other',
    ],
    'Mexico': [
      'Mexico City', 'Jalisco', 'Nuevo León', 'Estado de México',
      'Veracruz', 'Puebla', 'Guanajuato', 'Chihuahua', 'Other',
    ],
    'Indonesia': [
      'Jakarta', 'West Java', 'East Java', 'Central Java', 'Bali',
      'North Sumatra', 'South Sulawesi', 'Other',
    ],
    'Pakistan': [
      'Punjab', 'Sindh', 'Khyber Pakhtunkhwa', 'Balochistan',
      'Islamabad Capital Territory', 'Gilgit-Baltistan',
      'Azad Jammu & Kashmir',
    ],
    'Bangladesh': [
      'Dhaka', 'Chittagong', 'Rajshahi', 'Khulna', 'Barisal',
      'Sylhet', 'Rangpur', 'Mymensingh',
    ],
    'Nigeria': [
      'Lagos', 'Kano', 'Rivers', 'Oyo', 'Abuja FCT', 'Other',
    ],
    'Russia': [
      'Moscow', 'Saint Petersburg', 'Novosibirsk', 'Yekaterinburg',
      'Kazan', 'Other',
    ],
    'Italy': [
      'Lombardy', 'Lazio', 'Campania', 'Sicily', 'Veneto',
      'Emilia-Romagna', 'Piedmont', 'Tuscany', 'Other',
    ],
    'Spain': [
      'Madrid', 'Catalonia', 'Andalusia', 'Valencia', 'Galicia',
      'Basque Country', 'Castile and León', 'Other',
    ],
    'Turkey': [
      'Istanbul', 'Ankara', 'Izmir', 'Bursa', 'Antalya', 'Other',
    ],
    'Saudi Arabia': [
      'Riyadh', 'Makkah', 'Madinah', 'Eastern Province', 'Asir', 'Other',
    ],
    'United Arab Emirates': [
      'Abu Dhabi', 'Dubai', 'Sharjah', 'Ajman', 'Fujairah',
      'Ras Al Khaimah', 'Umm Al Quwain',
    ],
    'South Africa': [
      'Gauteng', 'Western Cape', 'KwaZulu-Natal', 'Eastern Cape',
      'Free State', 'Limpopo', 'Mpumalanga', 'North West', 'Northern Cape',
    ],
    'Egypt': [
      'Cairo', 'Alexandria', 'Giza', 'Luxor', 'Aswan', 'Other',
    ],
    'Thailand': [
      'Bangkok', 'Chiang Mai', 'Phuket', 'Nonthaburi', 'Other',
    ],
    'Vietnam': [
      'Ho Chi Minh City', 'Hanoi', 'Da Nang', 'Hai Phong', 'Other',
    ],
    'Philippines': [
      'Metro Manila', 'Cebu', 'Davao', 'Calabarzon', 'Other',
    ],
    'Malaysia': [
      'Kuala Lumpur', 'Selangor', 'Johor', 'Penang', 'Sabah',
      'Sarawak', 'Other',
    ],
    'Singapore': ['Singapore'],
    'New Zealand': [
      'Auckland', 'Wellington', 'Canterbury', 'Waikato', 'Other',
    ],
    'Ireland': [
      'Dublin', 'Cork', 'Galway', 'Limerick', 'Other',
    ],
    'Netherlands': [
      'North Holland', 'South Holland', 'Utrecht', 'North Brabant', 'Other',
    ],
    'Belgium': [
      'Flanders', 'Wallonia', 'Brussels-Capital',
    ],
    'Switzerland': [
      'Zurich', 'Bern', 'Geneva', 'Vaud', 'Basel', 'Other',
    ],
    'Austria': [
      'Vienna', 'Upper Austria', 'Lower Austria', 'Styria', 'Tyrol', 'Other',
    ],
    'Poland': [
      'Masovia', 'Lesser Poland', 'Greater Poland', 'Silesia', 'Other',
    ],
    'Sweden': [
      'Stockholm', 'Västra Götaland', 'Skåne', 'Other',
    ],
    'Norway': [
      'Oslo', 'Vestland', 'Trøndelag', 'Other',
    ],
    'Denmark': [
      'Capital Region', 'Central Denmark', 'Southern Denmark', 'Other',
    ],
    'Finland': [
      'Uusimaa', 'Pirkanmaa', 'Southwest Finland', 'Other',
    ],
    'Portugal': [
      'Lisbon', 'Porto', 'Algarve', 'Other',
    ],
    'Greece': [
      'Attica', 'Central Macedonia', 'Thessaly', 'Crete', 'Other',
    ],
    'Argentina': [
      'Buenos Aires', 'Córdoba', 'Santa Fe', 'Mendoza', 'Other',
    ],
    'Colombia': [
      'Bogotá', 'Antioquia', 'Valle del Cauca', 'Atlántico', 'Other',
    ],
    'Chile': [
      'Santiago Metropolitan', 'Valparaíso', 'Biobío', 'Other',
    ],
    'Peru': [
      'Lima', 'Arequipa', 'Cusco', 'Other',
    ],
    'Kenya': ['Nairobi', 'Mombasa', 'Kisumu', 'Other'],
    'Ghana': ['Greater Accra', 'Ashanti', 'Other'],
    'Tanzania': ['Dar es Salaam', 'Dodoma', 'Other'],
    'Ethiopia': ['Addis Ababa', 'Oromia', 'Amhara', 'Other'],
    'Nepal': ['Province 1', 'Madhesh', 'Bagmati', 'Gandaki', 'Lumbini', 'Karnali', 'Sudurpashchim'],
    'Sri Lanka': ['Western', 'Central', 'Southern', 'Other'],
    'Myanmar': ['Yangon', 'Mandalay', 'Other'],
    'Cambodia': ['Phnom Penh', 'Siem Reap', 'Other'],
    'Israel': ['Tel Aviv', 'Jerusalem', 'Haifa', 'Other'],
    'Jordan': ['Amman', 'Irbid', 'Zarqa', 'Other'],
    'Qatar': ['Doha', 'Al Rayyan', 'Other'],
    'Kuwait': ['Al Asimah', 'Hawalli', 'Other'],
    'Bahrain': ['Capital', 'Muharraq', 'Other'],
    'Oman': ['Muscat', 'Dhofar', 'Other'],
    'Iraq': ['Baghdad', 'Basra', 'Erbil', 'Other'],
    'Iran': ['Tehran', 'Isfahan', 'Fars', 'Other'],
    'Afghanistan': ['Kabul', 'Herat', 'Balkh', 'Other'],
    'Ukraine': ['Kyiv', 'Lviv', 'Odesa', 'Other'],
    'Romania': ['Bucharest', 'Cluj', 'Timișoara', 'Other'],
    'Czech Republic': ['Prague', 'Brno', 'Other'],
    'Hungary': ['Budapest', 'Pest', 'Other'],
    'Croatia': ['Zagreb', 'Split', 'Other'],
    'Serbia': ['Belgrade', 'Novi Sad', 'Other'],
    'Bulgaria': ['Sofia', 'Plovdiv', 'Other'],
    'Slovakia': ['Bratislava', 'Košice', 'Other'],
    'Slovenia': ['Ljubljana', 'Maribor', 'Other'],
    'Lithuania': ['Vilnius', 'Kaunas', 'Other'],
    'Latvia': ['Riga', 'Other'],
    'Estonia': ['Tallinn', 'Tartu', 'Other'],
    'Iceland': ['Reykjavik', 'Other'],
    'Luxembourg': ['Luxembourg City', 'Other'],
    'Malta': ['Valletta', 'Other'],
    'Cyprus': ['Nicosia', 'Limassol', 'Other'],
    'Morocco': ['Casablanca', 'Rabat', 'Marrakech', 'Other'],
    'Tunisia': ['Tunis', 'Sfax', 'Other'],
    'Algeria': ['Algiers', 'Oran', 'Other'],
    'Libya': ['Tripoli', 'Benghazi', 'Other'],
    'Cuba': ['Havana', 'Santiago de Cuba', 'Other'],
    'Jamaica': ['Kingston', 'Montego Bay', 'Other'],
    'Trinidad and Tobago': ['Port of Spain', 'San Fernando', 'Other'],
    'Costa Rica': ['San José', 'Other'],
    'Panama': ['Panama City', 'Other'],
    'Ecuador': ['Quito', 'Guayaquil', 'Other'],
    'Venezuela': ['Caracas', 'Zulia', 'Other'],
    'Uruguay': ['Montevideo', 'Other'],
    'Paraguay': ['Asunción', 'Other'],
    'Bolivia': ['La Paz', 'Santa Cruz', 'Other'],
    'Honduras': ['Tegucigalpa', 'Other'],
    'Guatemala': ['Guatemala City', 'Other'],
    'El Salvador': ['San Salvador', 'Other'],
    'Nicaragua': ['Managua', 'Other'],
    'Dominican Republic': ['Santo Domingo', 'Other'],
    'Haiti': ['Port-au-Prince', 'Other'],
    'Mongolia': ['Ulaanbaatar', 'Other'],
    'Uzbekistan': ['Tashkent', 'Other'],
    'Kazakhstan': ['Nur-Sultan', 'Almaty', 'Other'],
    'Turkmenistan': ['Ashgabat', 'Other'],
    'Kyrgyzstan': ['Bishkek', 'Other'],
    'Tajikistan': ['Dushanbe', 'Other'],
    'Georgia': ['Tbilisi', 'Other'],
    'Armenia': ['Yerevan', 'Other'],
    'Azerbaijan': ['Baku', 'Other'],
    'Fiji': ['Suva', 'Other'],
    'Papua New Guinea': ['Port Moresby', 'Other'],
    'Maldives': ['Malé', 'Other'],
    'Bhutan': ['Thimphu', 'Other'],
    'Brunei': ['Bandar Seri Begawan', 'Other'],
    'Laos': ['Vientiane', 'Other'],
    'Timor-Leste': ['Dili', 'Other'],
  };
}
