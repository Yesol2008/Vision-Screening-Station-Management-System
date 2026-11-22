<%--
Description: Shared helper methods; included with <%@ include %> on each page
--%>
<%!
	//helper method to escape HTML special characters
	 String escapeHtml(String input) {
		if (input == null) {
			return "";
		}
		return input.replace("&", "&amp;")
				.replace("<", "&lt;")
				.replace(">", "&gt;")
				.replace("\"", "&quot;")
				.replace("'", "&#39;");
	}

	//helper method to pad an id to two digits (1 -> 01) for P01 / E01
	String twoDigits(int n) {
		return (n < 10) ? "0" + n : String.valueOf(n);
	}
%>