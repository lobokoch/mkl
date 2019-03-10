package br.com.kerubin.dsl.mkl.generator

import static br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static br.com.kerubin.dsl.mkl.generator.Utils.*

class WebAppComponentCSSGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		generateComponent
	}
	
	def generateComponent() {
		val path = webAppDir
		val filePath = path + toWebAppComponentName() + '.css'
		generateFile(filePath, generateAppComponent)
	}
	
	def CharSequence generateAppComponent() {
		'''
		/* Write your CSS here. */
		
		/* start - hack to fix issue with dropdown caret position */
		/* WARNING: Also copy and past this code inside the style.css file */
		.ui-autocomplete-dd .ui-autocomplete-dropdown.ui-corner-all{
		  position:absolute;
		  transform: translateX(-100%);
		}
		/* end -  hack to fix issue with dropdown caret position */
		'''
	}
	
}