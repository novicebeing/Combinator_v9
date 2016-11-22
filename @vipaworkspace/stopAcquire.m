function stopAcquire(this)
    this.stopAcquireBoolean = true;
    this.acquiretab.AcquireButton.Enabled = true;
	this.acquiretab.AcquireSpectrumButton.Enabled = true;
    this.acquiretab.StopAcquireButton.Enabled = false;
end