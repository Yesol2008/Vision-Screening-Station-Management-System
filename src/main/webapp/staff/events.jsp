<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>
   
<%@ include file="/WEB-INF/auth/staffGuard.jsp" %>
<%
try {
	
	// Step 1: Load environment variables
	Dotenv dotenv =  Dotenv.configure()
	        .directory(application.getRealPath("/WEB-INF"))
	        .load();;

	String connURL = dotenv.get("DB_URL");
	String username = dotenv.get("DB_USERNAME");
	String password = dotenv.get("DB_PASSWORD");

    // Step 2: Load JDBC Driver (optional for newer drivers)
    Class.forName("com.mysql.cj.jdbc.Driver");
    		
    		
	String sql = "SELECT event_name, event_date, location, status FROM event";
    		
	
    	// Step 3: Establish database connection. Used try-with so that connection will close automatically
		try(Connection conn = DriverManager.getConnection(connURL, username, password);

	
		// Step 4: Create Statement object
		Statement stmt = conn.createStatement();){
			
			try(ResultSet rs = stmt.executeQuery(sql);){
				
				while(rs.next()){
					String event_name = rs.getString("event_name");
                    String event_date = rs.getString("event_date");
					
					
				}
    			
    			
    	

    			
			}
		}
	}catch (Exception e) {
        e.printStackTrace();
        application.log("Database connection error", e);
        out.println("Unable to connect to the database.");
    }


%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<body>

</body>
</html>