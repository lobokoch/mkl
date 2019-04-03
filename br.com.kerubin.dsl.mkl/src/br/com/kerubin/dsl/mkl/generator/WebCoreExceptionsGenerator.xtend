package br.com.kerubin.dsl.mkl.generator

import static br.com.kerubin.dsl.mkl.generator.Utils.*

class WebCoreExceptionsGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val path = getWebCoreDir
		path.generateExceptions
	}
	
	def generateExceptions(String securityPath) {
		val name = securityPath + 'exceptions'
		name.generateExceptionsTS
	}
	
	def generateExceptionsTS(String name) {
		val fileName = name + '.ts'
		generateFile(fileName, generateExceptionsTSContent)
	}
	
	def CharSequence generateExceptionsTSContent() {
		'''
		export class UserNotAuthenticatedError {
		
		}

		'''
	}
	
}