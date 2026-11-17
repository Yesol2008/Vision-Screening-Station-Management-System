<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@page import="io.github.cdimascio.dotenv.Dotenv"%>
<%@page import ="java.sql.*"%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<body>


<%
	try {
		
		// Step 1: Load environment variables
		Dotenv dotenv = Dotenv.load();

		String connURL = dotenv.get("DB_URL");
		String username = dotenv.get("DB_USERNAME");
		String password = dotenv.get("DB_PASSWORD");
		
		out.println("DB URL: " + connURL);
		out.println("Username: " + username);
		out.println("Password loaded: " + (password != null));

        // Step 2: Load JDBC Driver (optional for newer drivers)
        Class.forName("com.mysql.jdbc.Driver");
        		
		
        	// Step 3: Establish database connection
			Connection conn = DriverManager.getConnection(connURL, username, password);

			// Step 4: Create Statement object
			Statement stmt = conn.createStatement();

            // Step 5: Execute SQL command
			ResultSet rs = stmt.executeQuery("SELECT * FROM users");
			 
            // Step 6: Process results
            while (rs.next()) {
                int id = rs.getInt("id");
                String name = rs.getString("username");

                out.println("ID: " + id + ", Name: " + name + "<br>");
            
        }

    } catch (Exception e) {
        e.printStackTrace();
        application.log("Database connection error", e);
        out.println("Unable to connect to the database.");
    }
%>

</body>
</html>