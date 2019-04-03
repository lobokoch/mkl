package br.com.kerubin.dsl.mkl.generator

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2

class WebGenerator extends BaseGenerator {
	
	new(Resource resource, IFileSystemAccess2 fsa) {
		super(resource, fsa)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val IGeneratorExecutor[] generators = #[
			new WebEntityModelGenerator(this),
			new WebEntityCRUDComponentHTMLGenerator(this),
			new WebEntityCRUDComponentTSGenerator(this),
			new WebEntityCRUDComponentCSSGenerator(this),
			new WebEntityServiceGenerator(this),
			new WebEntityListComponentCSSGenerator(this),
			new WebEntityListComponentHTMLGenerator(this),
			new WebEntityListComponentTSGenerator(this),
			new WebAppComponentCSSGenerator(this),
			new WebAppComponentHTMLGenerator(this),
			new WebAppComponentTSGenerator(this),
			new WebAppModuleTSGenerator(this),
			new WebEntityTranslationGenerator(this),
			new WebNavbarServiceComponentHTMLGenerator(this),
			new WebNavbarComponentHTMLGenerator(this),
			new WebNavbarComponentTSGenerator(this),
			new WebNavbarComponentCSSGenerator(this),
			new WebSecurityLoginGenerator(this),
			new WebSecurityAuthServiceGenerator(this),
			new WebSecurityHttpClientTokenGenerator(this),
			new WebSecurityModuleGenerator(this),
			new WebSecurityRoutingModuleGenerator(this),
			new WebCoreModuleGenerator(this),
			new WebCoreMessageHandlerServiceGenerator(this),
			new WebSecurityAuthGuardGenerator(this),
			new WebCoreExceptionsGenerator(this),
			new WebEnumModelGenerator(this)
		]
		
		generators.forEach[it.generate]	 
	}
	
}