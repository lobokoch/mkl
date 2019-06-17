package br.com.kerubin.dsl.mkl.generator

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2

class JavaGenerator extends BaseGenerator {
	
	new(Resource resource, IFileSystemAccess2 fsa) {
		super(resource, fsa)
	}
	
	override generate() {
		if (canGenerateServiceBackend) {
			generateJavaFiles
		}
	}
	
	def generateJavaFiles() {
		val IGeneratorExecutor[] generators = #[
			new JavaProjectsGenerator(this),
			new JavaServerConfigGenerator(this),
			new JavaCustomResponseEntityExceptionHandlerGenerator(this),
			new JavaEntityJPAGenerator(this),
			new JavaEntityRepositoryGenerator(this),
			new JavaEntityServiceGenerator(this),
			new JavaEntityDTOGenerator(this),			
			new JavaEntityDomainEventGenerator(this),			
			new JavaEntitySubscriberEventRabbitConfigGenerator(this),			
			new JavaEntitySubscriberEventHandlerGenerator(this),			
			new JavaEntitySumFieldsGenerator(this),	
			new JavaEntityMakeCopiesGenerator(this),	
			new JavaEnumGenerator(this),
			new JavaEntityLookupResultDTOGenerator(this),
			new JavaEntityListFilterGenerator(this),
			new JavaEntityAutoCompleteGenerator(this),
			new JavaEntityListFilterAutoCompleteGenerator(this),
			new JavaObjectMapperGenerator(this),
			new JavaEntityDTOConverterGenerator(this),
			new JavaServiceConstantsGenerator(this),
			new JavaClientPageResultGenerator(this),
			new JavaEntityControllerGenerator(this),
			new JavaPostgreSQLGenerator(this),
			new JavaServerHttpFilterGenerator(this),
			new JavaServiceHandlerInterceptorAdapterGenerator(this),
			new JavaServiceWebMvcConfigurerAdapterGenerator(this),
			new JavaMessagingAfterReceivePostProcessorsGenerator(this),
			new JavaEntityRuleFunctionsGenerator(this)
		]
		
		generators.forEach[it.generate]	 
	}
	
}