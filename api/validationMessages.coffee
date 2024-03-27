import SimpleSchema from 'meteor/aldeed:simple-schema';
import find from 'lodash/find';


export regExpMessages_de = [
    exp: SimpleSchema.RegEx.Email,
    msg: 'muss eine gültige Adresse sein'
  ,
    exp: SimpleSchema.RegEx.EmailWithTLD,
    msg: 'muss eine gültige E-Mail Adresse sein'
  ,
    exp: SimpleSchema.RegEx.Domain,
    msg: 'muss eine gültige Domain sein'
  ,
    exp: SimpleSchema.RegEx.WeakDomain,
    msg: 'muss eine gültige Domain sein'
  ,
    exp: SimpleSchema.RegEx.IP,
    msg: 'muss eine gültige IPv4 or IPv6 Adresse sein'
  ,
    exp: SimpleSchema.RegEx.IPv4,
    msg: 'muss eine gültige IPv4 Adresse sein'
  ,
    exp: SimpleSchema.RegEx.IPv6,
    msg: 'muss eine gültige IPv6 Adresse sein'
  ,
    exp: SimpleSchema.RegEx.Url,
    msg: 'muss eine gültige URL sein'
  ,
    exp: SimpleSchema.RegEx.Id,
    msg: 'muss eine gültige alphanumerische ID sein'
  ,
    exp: SimpleSchema.RegEx.ZipCode,
    msg: 'muss eine gültige PLZ sein'
  ,
    exp: SimpleSchema.RegEx.Phone,
    msg: 'muss eine gültige Telefonnummer sein'
]

export de =
  required: '{{{label}}} wird benötigt'
  minString: '{{{label}}} muss mindestens {{min}} Zeichen lang sein'
  maxString: '{{{label}}} darf höchstens {{max}} Zeichen lang sein'
  minNumber: '{{{label}}} muss mindestens {{min}} sein'
  maxNumber: '{{{label}}} darf höchstens {{max}} sein'
  minNumberExclusive: '{{{label}}} muss größer als {{min}} sein'
  maxNumberExclusive: '{{{label}}} muss weniger als {{max}} sein'
  minDate: '{{{label}}} darf nicht vor {{min}} sein'
  maxDate: '{{{label}}} darf nicht nach {{max}} sein'
  badDate: '{{{label}}} ist kein gültiges Datum'
  minCount: 'Sie müssen mindestens {{minCount}} Einträge angeben'
  maxCount: 'Sie dürfen nicht mehr als {{maxCount}} Einträge angeben'
  noDecimal: '{{{label}}} muss eine ganze Zahl sein'
  notAllowed: '{{{value}}} ist kein erlaubter Wert'
  expectedType: '{{{label}}} muss vom Typ {{dataType}} sein'
  name_not_unique: 'Es gibt bereits eine Regel mit diesem Namen'
  codeList_not_unique: 'Es gibt bereits eine Code Liste mit diesem Namen'
  keyNotInSchema: '{{name}} wird vom Schema nicht erlaubt'
  regEx:
    ({label, regExp}) ->
      regExpMessage =
        if regExp and (label is 'Passwort' or label is 'Neues Passwort')
          " muss mindestens einen Großbuchstabe, einen Kleinbuchstabe,
          und eine Ziffer enthalten und mindestens 8 Zeichen lang sein."
        else
          msgObj = find regExpMessages_de, (o) -> o.exp?.toString() is regExp
          msgObj?.msg ? '- RegExp Validierung fehlgeschlagens'
      "#{label} #{regExpMessage}"


export setDefaultValidationMessages = (initialLanguage = 'de',  messages = {de}) ->
  SimpleSchema.setDefaultMessages {initialLanguage, messages}