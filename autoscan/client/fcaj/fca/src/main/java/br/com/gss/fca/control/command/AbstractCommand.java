package br.com.gss.fca.control.command;

import br.com.gss.fca.Messages;
import br.com.gss.fca.exception.FCAException;
import br.com.gss.fca.gui.FeedbackDelegate;

public abstract class AbstractCommand {

	protected FeedbackDelegate feebackWindow;

	public AbstractCommand(FeedbackDelegate feebackWindow) {
		this.feebackWindow = feebackWindow;
	}
	
	public final void execute(){
		if(getCommandName()!=null){
			this.feebackWindow.onFeedback("\t>> "+getCommandName()+" | " +Messages.getString("message.executing"));
		}
		try {
			this.executeCommand();
		} catch (FCAException e) {
			this.feebackWindow.onError(e.getMessage(), e);
		}
	}
	
	protected abstract void executeCommand()  throws FCAException;
	
	public abstract String getCommandName();
	


}
