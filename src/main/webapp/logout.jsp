<%--
Author: Htet Yamin Aung (P2535607)
Date: 23/11/2026
Description: ST0510/JAD Assignment 1 - Log out (no HTML; redirects only)
--%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
	//end the session: removes userId and every other attribute stored in it
	session.invalidate();

	//back to the login page with a confirmation message
	response.sendRedirect("login.jsp?msg=loggedOut");
%>