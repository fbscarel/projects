/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

package br.com.gss.fca.gui.impl;

import javax.swing.JOptionPane;
import javax.swing.SwingUtilities;

import br.com.gss.fca.Messages;
import br.com.gss.fca.control.FlowControl;
import br.com.gss.fca.gui.AbstractPanel;
import br.com.gss.fca.gui.MainWindow;
import br.com.gss.fca.gui.StateWindow.STATE;


/**
 *
 * @author Paula.Fernandes
 */
public class AnalysisPanel extends AbstractPanel{

	private static final long serialVersionUID = 1L;
	
	
	public AnalysisPanel(MainWindow mainWindow) {
		super(mainWindow);
	    initComponents();
	}

	 private void initComponents() {

        txtTitle = new javax.swing.JLabel();
        txtDescription = new javax.swing.JLabel();
        scrollPanel = new javax.swing.JScrollPane();
        txtLog = new javax.swing.JTextPane();
        progressBar = new javax.swing.JProgressBar();

        setPreferredSize(new java.awt.Dimension(500, 300));

        txtTitle.setFont(new java.awt.Font("Tahoma", 1, 12));
        txtTitle.setText(Messages.getString("window.execute.title"));
        txtDescription.setText(Messages.getString("window.execute.description"));

        scrollPanel.setViewportView(txtLog);

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(this);
        this.setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addComponent(scrollPanel, javax.swing.GroupLayout.Alignment.TRAILING, javax.swing.GroupLayout.PREFERRED_SIZE, 0, Short.MAX_VALUE)
                    .addComponent(txtDescription, javax.swing.GroupLayout.Alignment.TRAILING, javax.swing.GroupLayout.DEFAULT_SIZE, 410, Short.MAX_VALUE)
                    .addComponent(txtTitle, javax.swing.GroupLayout.Alignment.TRAILING, javax.swing.GroupLayout.DEFAULT_SIZE, 380, Short.MAX_VALUE)
                    .addComponent(progressBar, javax.swing.GroupLayout.Alignment.TRAILING, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
                .addContainerGap())
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addComponent(txtTitle, javax.swing.GroupLayout.PREFERRED_SIZE, 22, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(txtDescription, javax.swing.GroupLayout.PREFERRED_SIZE, 32, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(scrollPanel, javax.swing.GroupLayout.DEFAULT_SIZE, 199, Short.MAX_VALUE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                .addComponent(progressBar, javax.swing.GroupLayout.PREFERRED_SIZE, 20, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addContainerGap())
        );
    }


    private javax.swing.JProgressBar progressBar;
    private javax.swing.JScrollPane scrollPanel;
    private javax.swing.JLabel txtDescription;
    private javax.swing.JTextPane txtLog;
    private javax.swing.JLabel txtTitle;
	private Task task;
    
    
    private void updateText(String string) {
    	if(txtLog.getText()==null || txtLog.getText().length()==0){
    		txtLog.setText("");
    	}
    	txtLog.setText(txtLog.getText() +  string + "\n");		
    }


	public void onFeedback(String message) {
		this.updateText(message);
	}
	
    public void onError(String error, Exception e) {
    	this.updateText("\t\tErro: " + error);
    	e.printStackTrace();
    }
    
	@Override
	public boolean allowNext() {
		if(this.feedbackDelegate.getCurrentState()==STATE.ANALYSIS_WAITING){
			return true;
		}else if(this.feedbackDelegate.getCurrentState()==STATE.ANALYSIS_RUNNING){
			return false;
		}else if(this.feedbackDelegate.getCurrentState()==STATE.ANALYSIS_ENDED){
			return true;
		}
		return false;
	}

	@Override
	public boolean allowPrevious() {
		if(this.feedbackDelegate.getCurrentState()==STATE.ANALYSIS_WAITING){
			return true;
		}else if(this.feedbackDelegate.getCurrentState()==STATE.ANALYSIS_RUNNING){
			return false;
		}else if(this.feedbackDelegate.getCurrentState()==STATE.ANALYSIS_ENDED){
			return true;
		}
		return false;
	}

	@Override
	public void onNext() {
		if(this.feedbackDelegate.getCurrentState()==STATE.ANALYSIS_WAITING){
			this.startAnalysis();
			this.feedbackDelegate.setNewState(STATE.ANALYSIS_RUNNING);
		}else if(this.feedbackDelegate.getCurrentState()==STATE.ANALYSIS_RUNNING){
			this.pauseAnalysis();			
			this.feedbackDelegate.setNewState(STATE.ANALYSIS_ENDED);
		}else if(this.feedbackDelegate.getCurrentState()==STATE.ANALYSIS_ENDED){
			System.exit(0);
		}
	}

	@Override
	public void onPrevious() {
		stopAnalysis();
	}
	
	
	
	/**
	 * Methods that control thread execution
	 */
	private void pauseAnalysis() {
		if(this.task!=null){
			this.task.pause();
			feedbackDelegate.onFeedback(Messages.getString("message.execution.pause.required"));
		}
	}

	private void stopAnalysis() {
		SwingUtilities.invokeLater(new Runnable() {
	        public void run() {
	        	feedbackDelegate.onFeedback(Messages.getString("message.execution.finished"));
	        }
		});
		feedbackDelegate.setNewState(STATE.ANALYSIS_ENDED);
	}

	public void pausedAnalysis() {
		SwingUtilities.invokeLater(new Runnable() {
	        public void run() {
	        	feedbackDelegate.onFeedback(Messages.getString("message.execution.paused"));
	        }
		});
		feedbackDelegate.setNewState(STATE.ANALYSIS_WAITING);		
	}

	private void startAnalysis(){
		if(this.task!=null){
			this.task.pause();
			this.task.interrupt();
			this.task = null;
		}
		this.task = new Task();
        task.start();
        SwingUtilities.invokeLater(new Runnable() {
	        public void run() {
	        	feedbackDelegate.onFeedback(Messages.getString("message.execution.started"));
	        }
		});
	}
	
	@Override
	public void showPopupDialog(String message) {
		JOptionPane.showMessageDialog(this, message);
	}

	@Override
	public RETURN_CONFIRMATION showConfirmationDialog(String message) {
		int r = JOptionPane.showConfirmDialog(this, message, "Selecione opções", JOptionPane.YES_NO_OPTION);
		switch (r) {
			case JOptionPane.OK_OPTION:
				return RETURN_CONFIRMATION.OK;
			default:
				return RETURN_CONFIRMATION.CANCEL;
		}
	}
	
	/**
	 * Thread that control the execution of analysis.
	 * @author Paula.Fernandes
	 *
	 */
	private class Task extends Thread{
		
		private boolean pause = false;

		public void run(){
			FlowControl control = FlowControl.getInstance();
			control.registerDelegate(feedbackDelegate);
			control.restart();
			final float percentage = ((float)100 / (float)control.commandsCount());
			for (int i = 0; i < control.commandsCount(); i++) {
				if(!this.pause){
					if(control.hasNextCommand()){
						final int temp = i;
						updateProgressBar(percentage, temp, true);
						control.executeNextCommand();
						updateProgressBar(percentage, temp, false);
					}else{
						stopAnalysis();
						return;	
					}
				}else{
					pausedAnalysis();
					return;
				}
			}
			updateProgressBar(percentage, control.commandsCount()-1, false);
			stopAnalysis();
		}

		private void updateProgressBar(final float percentage, final int temp, final boolean partial) {
			SwingUtilities.invokeLater(new Runnable() {
				public void run() {
					int value = (int)(percentage * (temp+1));
					if(partial){
						value = value - (int)(percentage/(float)2);
						if(value<0){
							value = 0;
						}
					}
					progressBar.setValue(value);
				}
			});
			
		}

		public void pause() {
			this.pause = true;
		}
	}


	
 
	
}
