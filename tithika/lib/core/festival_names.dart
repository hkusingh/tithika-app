import '../models/app_settings.dart';

/// Translates a canonical English festival key (as returned by
/// [FestivalDetector.detect]) into the user's display language.
///
/// The English name is the single source of truth. Adding a new language
/// means adding one new map here — no other files need to change.
abstract final class FestivalNames {
  static String? localize(String? key, AppLanguage language) {
    if (key == null) return null;
    return switch (language) {
      AppLanguage.english      => key,
      AppLanguage.hindiLatin   => key,
      AppLanguage.hindiDevanagari => _deva[key] ?? key,
    };
  }

  static const _deva = <String, String>{
    'Baisakhi / Vishu':           'बैसाखी / विषु',
    'Makar Sankranti / Pongal':   'मकर संक्रांति / पोंगल',
    'Chaitra Navratri':           'चैत्र नवरात्रि',
    'Maha Ashtami':               'महा अष्टमी',
    'Ram Navami':                 'राम नवमी',
    'Hanuman Jayanti':            'हनुमान जयंती',
    'Holi':                       'होली',
    'Akshaya Tritiya':            'अक्षय तृतीया',
    'Buddha Purnima':             'बुद्ध पूर्णिमा',
    'Nirjala Ekadashi':           'निर्जला एकादशी',
    'Vat Savitri':                'वट सावित्री',
    'Rath Yatra':                 'रथ यात्रा',
    'Devshayani Ekadashi':        'देवशयनी एकादशी',
    'Guru Purnima':               'गुरु पूर्णिमा',
    'Nag Panchami':               'नाग पंचमी',
    'Raksha Bandhan':             'रक्षा बंधन',
    'Krishna Janmashtami':        'कृष्ण जन्माष्टमी',
    'Ganesh Chaturthi':           'गणेश चतुर्थी',
    'Anant Chaturdashi':          'अनंत चतुर्दशी',
    'Sharad Navratri':            'शारद नवरात्रि',
    'Maha Navami':                'महा नवमी',
    'Vijayadashami':              'विजयदशमी',
    'Sharad Purnima':             'शरद पूर्णिमा',
    'Dhanteras':                  'धनतेरस',
    'Naraka Chaturdashi':         'नरक चतुर्दशी',
    'Diwali':                     'दीपावली',
    'Govardhan Puja':             'गोवर्धन पूजा',
    'Bhai Dooj':                  'भाई दूज',
    'Chhath — Nahay Khay':        'छठ — नहाय खाय',
    'Chhath — Kharna':            'छठ — खरना',
    'Chhath — Sandhya Arghya':    'छठ — संध्या अर्घ्य',
    'Chhath — Usha Arghya':       'छठ — उषा अर्घ्य',
    'Devutthana Ekadashi':        'देवउठानी एकादशी',
    'Kartik Purnima':             'कार्तिक पूर्णिमा',
    'Gita Jayanti':               'गीता जयंती',
    'Vasant Panchami':            'वसंत पंचमी',
    'Maha Shivaratri':            'महाशिवरात्रि',
    'Holika Dahan':               'होलिका दहन',
  };
}
