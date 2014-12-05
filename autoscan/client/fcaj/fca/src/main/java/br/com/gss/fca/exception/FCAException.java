package br.com.gss.fca.exception;

/**
 * Custom exception to be handled by FCA application.
 * 
 * @author Paula.Fernandes
 */
public class FCAException extends RuntimeException {

	private static final long serialVersionUID = 1L;
	
	public FCAException(String message){
		super(message);
	}
	
	public FCAException(String message, Exception e){
		super(message, e);
	}

}
