package br.com.kerubin.dsl.mkl.generator

import org.eclipse.xtext.generator.OutputConfigurationProvider
import org.eclipse.xtext.generator.OutputConfiguration
import org.eclipse.xtext.generator.IFileSystemAccess

class MklOutputConfigurationProvider extends OutputConfigurationProvider {
	
	public static val DEFAULT_OUTPUT_DIRECTORY = "."
	public static val APP_OUTPUT_DIRECTORY = DEFAULT_OUTPUT_DIRECTORY + "/modules/app/"
	public static val OUTPUT_KEEPED = "OUTPUT_KEEPED"
	
	
	override getOutputConfigurations() {
		val defaultOutput = new OutputConfiguration(IFileSystemAccess.DEFAULT_OUTPUT)
		defaultOutput.description = "Default and base output."
		defaultOutput.outputDirectory = DEFAULT_OUTPUT_DIRECTORY
		defaultOutput.createOutputDirectory = true
		
		
		val outputConfigKeepResources = new OutputConfiguration(OUTPUT_KEEPED)
		outputConfigKeepResources.description = "Keep generated files"
		outputConfigKeepResources.outputDirectory = APP_OUTPUT_DIRECTORY
		outputConfigKeepResources.createOutputDirectory = true
		outputConfigKeepResources.overrideExistingResources = false
		outputConfigKeepResources.setDerivedProperty = false
		outputConfigKeepResources.canClearOutputDirectory = false
		outputConfigKeepResources.cleanUpDerivedResources = false
		
		newHashSet(defaultOutput, outputConfigKeepResources)
	}
	
}