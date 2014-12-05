package br.com.gss.fca.gui;



/**
 * Class defines what a panel must implement to be included by the main window.
 * @author Paula.Fernandes
 */
public abstract class AbstractPanel extends javax.swing.JPanel implements FeedbackDelegate{

	private static final long serialVersionUID = 1L;
	public enum EVENT_TYPE { NEXT, PREVIOUS}

	protected  MainWindow feedbackDelegate;
	
	public AbstractPanel(MainWindow mainWindow) {
		this.feedbackDelegate = mainWindow;
	}
	
	public final void refreshFeedback() {
		this.feedbackDelegate.refreshFeedback();
	}

	/**
	 * Method that the main window uses to decide if it should enable or no the Next button
	 * @return
	 * 	True if it should enable.
	 *  False if it should enable.
	 */
	public abstract boolean allowNext();
	
	/**
	 * Method that the main window uses to decide if it should enable or no the Previous button
	 * 	True if it should enable button.
	 *  False if it should enable button.
	 */
	public abstract boolean allowPrevious();
	
	/**
	 * Method called by the main window when the user clicks "Next" button
	 * @return
	 */
	public abstract void onNext();

	/**
	 * Method called by the main window when the user clicks "Previous" button
	 * @return
	 */
	public abstract void onPrevious();

	
	public void showPopupDialog(String message) {
		//DO NOTHING
	}

	public RETURN_CONFIRMATION showConfirmationDialog(String message) {
		return RETURN_CONFIRMATION.CANCEL;
	}
}
