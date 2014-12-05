package br.com.gss.fca.control.command;

import java.io.BufferedReader;
import java.io.InputStreamReader;

import br.com.gss.fca.exception.FCAException;
import br.com.gss.fca.gui.FeedbackDelegate;


public class ExecuteCommand extends AbstractCommand{

	protected String[] parameters;

	public ExecuteCommand(FeedbackDelegate feebackWindow, String []parameters) {
		super(feebackWindow);
		this.parameters = parameters;
	}

	@Override
	public void executeCommand() throws FCAException {

		validateParameters();
	
		try {
	      String line;
	      Process process = new ProcessBuilder(parameters).start();
	      BufferedReader input =new BufferedReader(new InputStreamReader(process.getInputStream()));
	      while ((line = input.readLine()) != null) {
	    	  System.out.println(line);
	      }
	      process.waitFor();
	      input.close();
	    } catch (Exception err) {
	    	throw new FCAException(err.getMessage(),err);
	    }

	}

	protected void validateParameters() throws FCAException {
		
	}

	@Override
	public String getCommandName() {
		return null;
	}
	
}
