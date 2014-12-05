package br.com.gss.fca.gui;


/**
 * Interface defines method that must be implemented by any GUI JFrame or Panel in the fca
 * @author Paula.Fernandes
 *
 */
public interface FeedbackDelegate {

	
	enum RETURN_CONFIRMATION {OK, CANCEL};
	
	/**
	 * Method called when an error should be informed to the final user.
	 * @param error - Error message. It can be null.
	 * @param e - Exception with more details about the error. It can be null.
	 */
	void onError(String error, Exception e);
	
	/**
	 * Method called when a message should be informed to the final user.
	 * @param message Message to the final user.
	 */
	void onFeedback(String message);
	
	/**
	 * Method called when the window should be repainted
	 */
	void refreshFeedback();

	/**
	 * Method called when a popup must be shown to the user
	 * @param message - Message to be popped up 
	 */
	void showPopupDialog(String message);
	
	/**
	 * Method called when a popup must be shown to the user
	 * @param message - Message to be popped up 
	 */
	RETURN_CONFIRMATION showConfirmationDialog(String message);
	
}
