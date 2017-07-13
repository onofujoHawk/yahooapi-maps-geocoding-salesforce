/**
 * @author Onofrio Falco
 * @date May 2017
 *
 * @description Call yahoo API Rest controller
 * Class: YahooAPIsRestController.cls
 */
public class YahooAPIsRestController 
{
	public String geoAddress {get; set;}
	public String address {get; set;}
	public String city {get; set;}
	public String state {get; set;}
	
	//Yahoo App ID
	private String appId {
		get;
		set {
			appId = 'DaqEkjjV34FCuqDUvZN92rQ9WWVQz58c0WHWo2hRGBuM310.qXefuBVwvJQaf1nnMCxSbg--';
		}
	}

	//Submit action
	public PageReference submit() {
		List<GeoResult> geoResults = this.getMap(address, city, state);
		if (geoResults == null) return null;
		System.debug('*** First result: ' + geoResults[0].toDisplayString());
		geoAddress = geoResults[0].toDisplayString();
		return null;
	}

	//Chiama il servizio REST con l'indirizzo
	public List<GeoResult> getMap(String street, String city, String state) {
		HttpRequest req = new HttpRequest();
		Http http = new Http();
		List<GeoResult> geoResults = new List<GeoResult>();

		//Setta il metodo di request
		req.setMethod('GET');

		//setta l'url di Yahoo maps compreso di indirizzo
		String mapurl = 'http://local.yahooapis.com/MapsService/V1/geocode?appid=' + appId
            + '&amp;street=' + EncodingUtil.urlEncode(street,'UTF-8')
            + '&amp;city=' + EncodingUtil.urlEncode(city,'UTF-8')
            + '&amp;state=' + EncodingUtil.urlEncode(state,'UTF-8');

        req.setEndpoint(mapurl);
        HttpResponse resp = http.send(req);
        String respBody = resp.getBody();

        if (resp.getStatusCode() == 503) {
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, resp.getStatus()));
        	return null;
        }

    	Dom.Document doc = new Dom.Document();
        doc.load(respBody);
        for (Dom.XmlNode node : doc.getRootElement().getChildElements()) {
        	if (node.getNodeType() == Dom.XMLNodeType.ELEMENT) {
    			geoResults.add(toGeoResult(node));
    		}
        }
        return geoResults;
	}

	private GeoResult toGeoResult(Dom.XmlNode node) {
		GeoResult geo = new GeoResult();
		geo.latitude = node.getChildElement('Latitude', node.getNamespace()).getText();
		geo.longitude = node.getChildElement('Longitude', node.getNamespace()).getText();
		geo.address = node.getChildElement('Address', node.getNamespace()).getText();
		geo.city = node.getChildElement('City', node.getNamespace()).getText();
		geo.state = node.getChildElement('State', node.getNamespace()).getText();
		geo.zip = node.getChildElement('Zip', node.getNamespace()).getText();
		return geo;
	}

	private Boolean htmlMatcher(String body) {
		Pattern p = Pattern.compile('</?\\w+((\\s+\\w+(\\s*=\\s*(?:".*?"|\'.*?\'|[\\^\'">\\s]+))?)+\\s*|\\s*)/?>');
		Matcher m = p.matcher(body);
        if (m.find()) 
            return true;
        else 
            return false;
	}

	//inner class
	private without sharing class GeoResult {
		public String latitude;
        public String longitude;
        public String address;
        public String city;
        public String state;
        public String zip;
        public String toDisplayString() {
            return address + ', '
            + city + ', '
            + state + ', '
            + zip + ' ['
            + latitude + ', '
            + longitude + ']';
        }
	}

	//for test purpose
	private static final String stubXml = '<?xml version="1.0" encoding="UTF-8"?><ResultSet xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="urn:yahoo:maps" xsi:schemaLocation="urn:yahoo:maps http://local.yahooapis.com/MapsService/V1/GeocodeResponse.xsd"><Result precision="address"><Latitude>37.416384</Latitude><Longitude>-122.024853</Longitude><Address>701 FIRST AVE</Address><City>SUNNYVALE</City><State>CA</State><Zip>94089-1019</Zip><Country>US</Country></Result></ResultSet>';

}