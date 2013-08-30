package com.alvaroreig.varios;

import java.util.regex.Pattern;

	/***************************************************************/
	/* Álvaro Reig González.                                       */
	/* http://www.alvaroreig.com                                   */
	/* https://github.com/alvaroreig/                              */
	/* GPL v3                                                      */
	/***************************************************************/

public final class NIFvalidator {
	public static final String nifPattern="^\\d\\d\\d\\d\\d\\d\\d\\d[A-Za-z]$";
	public static final String NIF_STRING_ASOCIATION = "TRWAGMYFPDXBNJZSQVHLCKE";
	 
	/***************************************************************/
	/* Method that validates an Spanish full identity number (NIF).*/
	/* A NIF is formed of eight numbers plus a single letter for   */
	/* checking purpose. The method returns:                       */
	/* 0: correct NIF                                              */
	/* 1: incorrect string format                                  */
	/* 2: incorrect check letter                                   */
	/***************************************************************/
	 
	 public static int validate(String nif){
		 int status=0;
		 
		 //String size
		 if (!Pattern.matches(nifPattern, nif))
			 status =1;
		 
		 //Letter correct
		 if (status == 0){
			 String dni = nif.substring(0,8);
			 Character letter = nif.charAt(8);
			 Character expectedLetter = NIF_STRING_ASOCIATION.charAt(Integer.parseInt(dni) % 23);
			 if (!(Character.toUpperCase(letter) == expectedLetter)){
				 status = 2;
			 }
		 }
		 
		 return status;
		 
	 }
}