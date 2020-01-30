package br.com.kerubin.dsl.mkl.generator

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import br.com.kerubin.dsl.mkl.generator.web.account.WebConfigNewAccountGenerator
import br.com.kerubin.dsl.mkl.generator.web.account.WebConfirmAccountGenerator
import br.com.kerubin.dsl.mkl.generator.web.account.WebNewAccountGenerator
import br.com.kerubin.dsl.mkl.generator.web.account.WebUserAccountServiceGenerator
import br.com.kerubin.dsl.mkl.generator.web.others.WebStylesGenerator
import br.com.kerubin.dsl.mkl.generator.web.diretive.WebFocusDirectiveGenerator
import br.com.kerubin.dsl.mkl.generator.web.account.WebAccountModuleGenerator
import br.com.kerubin.dsl.mkl.generator.web.searchcep.WebSearchCEPServiceGenerator
import br.com.kerubin.dsl.mkl.generator.web.searchcep.WebSearchCEPDTOServiceGenerator
import br.com.kerubin.dsl.mkl.generator.web.analitycs.WebAnalitycsGenerator
import br.com.kerubin.dsl.mkl.generator.web.others.WebIndexHTMLGenerator

class WebGenerator extends BaseGenerator {
	
	new(Resource resource, IFileSystemAccess2 fsa) {
		super(resource, fsa)
	}
	
	override generate() {
		if (service.canGenerateFrontend) {
			generateFiles
		}
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
			new WebMenuGenerator(this),			
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
			new WebSecurityLogoutServiceGenerator(this),
			new WebEnvironmentsGenerator(this),
			new WebEnumModelGenerator(this),
			
			new WebAccountModuleGenerator(this),
			new WebConfigNewAccountGenerator(this),
			new WebConfirmAccountGenerator(this),
			new WebNewAccountGenerator(this),
			new WebUserAccountServiceGenerator(this),
			
			new WebStylesGenerator(this),
			new WebFocusDirectiveGenerator(this),
			new WebEntityRoutingModuleGenerator(this),
			new WebEntityModuleGenerator(this),
			new WebAppRoutingModuleGenerator(this),
			
			new WebSearchCEPServiceGenerator(this),
			new WebSearchCEPDTOServiceGenerator(this),
			
			new WebAnalitycsGenerator(this),
			new WebIndexHTMLGenerator(this)
			
		]
		
		generators.forEach[it.generate]	 
	}
	
}