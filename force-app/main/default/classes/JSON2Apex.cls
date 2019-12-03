public class JSON2Apex {

	public List<CostShares> costShares;
	public String planName;

	public class CostShares {
		public String costShareType;
		public Integer min;
		public Integer max;
	}

	
	public static JSON2Apex parse(String json) {
		return (JSON2Apex) System.JSON.deserialize(json, JSON2Apex.class);
	}
}