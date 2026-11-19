<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@page import="io.github.cdimascio.dotenv.Dotenv"%>
<%@page import ="java.sql.*"%>
<%@page import = "org.mindrot.jbcrypt.BCrypt"%>
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
        Class.forName("com.mysql.cj.jdbc.Driver");
        		
		
        	// Step 3: Establish database connection. Used try-with so that connection will close automatically
			Connection conn = DriverManager.getConnection(connURL, username, password);
			out.println("Database connected successfully!");

		
			// Step 4: Create Statement object
			Statement stmt = conn.createStatement();
			
			
			
			//reset db
			stmt.execute("SET FOREIGN_KEY_CHECKS = 0");

			stmt.executeUpdate("TRUNCATE TABLE registrations");
			stmt.executeUpdate("TRUNCATE TABLE participants");
			stmt.executeUpdate("TRUNCATE TABLE events");
			stmt.executeUpdate("TRUNCATE TABLE users");

			stmt.execute("SET FOREIGN_KEY_CHECKS = 1");
			
					
					//for users
					 String[] usernames = {
					            "admuser",
					            "john123",
					            "mary123",
					            "alex123",
					            "sarah123"
					        };

					        String[] passwords = {
					            "Staff@123",
					            "Participant@123",
					            "Participant@456",
					            "Participant@789",
					            "Participant@000"
					        };

					        String[] roles = {
					            "STAFF",
					            "PARTICIPANT",
					            "PARTICIPANT",
					            "PARTICIPANT",
					            "PARTICIPANT"
					        };
					        
					String sql = "INSERT INTO users "
					              + "(username, password_hash, role) "
					              + "VALUES (?, ?, ?)";
				    
					PreparedStatement pstmt = conn.prepareStatement(sql);

			        for (int i = 0; i < usernames.length; i++) {

			            String hashedPassword = BCrypt.hashpw(
			                passwords[i],
			                BCrypt.gensalt(10)
			            );

			            pstmt.setString(1, usernames[i]);
			            pstmt.setString(2, hashedPassword);
			            pstmt.setString(3, roles[i]);

			            pstmt.executeUpdate();
			        }

			 //inserting in participants
			 
			String insertParticipants =
    			"INSERT INTO participants "
    			+ "(user_id, full_name, date_of_birth, email, contact_number, address) "
    			+ "VALUES "
    			+ "(2, 'John Tan', '2003-05-12', 'john@gmail.com', '91234567', 'Tampines, Singapore'), "
    			+ "(3, 'Mary Lim', '2004-08-21', 'mary@gmail.com', '92345678', 'Bedok, Singapore'), "
   	 			+ "(4, 'Alex Wong', '2002-11-03', 'alex@gmail.com', '93456789', 'Jurong East, Singapore'), "
    			+ "(5, 'Sarah Lee', '2003-02-15', 'sarah@gmail.com', '94567890', 'Woodlands, Singapore')";

			stmt.executeUpdate(insertParticipants);
			
			//inserting event
			
			String insertEvents =
    		"INSERT INTO events "
   				+ "(event_name, event_date, location, status) "
    			+ "VALUES "
			    + "('Community Clean-Up', '2026-12-05', 'East Coast Park', 'Upcoming'), "
    			+ "('Charity Run 2026', '2026-12-15', 'Marina Bay', 'Upcoming'), "
    			+ "('Coding Workshop', '2026-11-10', 'Singapore Polytechnic', 'Completed'), "
    			+ "('Volunteer Orientation', '2026-11-20', 'Community Centre', 'Upcoming'), "
    			+ "('Food Donation Drive', '2026-11-01', 'Tampines Hub', 'Cancelled')";

			stmt.executeUpdate(insertEvents);

			//inserting registration
			
			String insertRegistrations =
		    "INSERT INTO registrations "
			    + "(participant_id, event_id, status) "
			    + "VALUES "
			    + "(1, 1, 'Registered'), "
			    + "(1, 2, 'Registered'), "
			    + "(2, 1, 'Attended'), "
			    + "(2, 3, 'Attended'), "
			    + "(3, 2, 'Withdrawn'), "
			    + "(4, 4, 'Registered')";

			stmt.executeUpdate(insertRegistrations);

			out.println("Query executed successfully!");


			
			//display users

		out.println("<h3>Datas inserted successfully!</h3>");
		
    	stmt.close();
		conn.close();
		
    } catch (Exception e) {
        e.printStackTrace();
        application.log("Database connection error", e);
        out.println("Unable to connect to the database.");
    }
%>
</body>
</html>