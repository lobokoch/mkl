package br.com.kerubin.dsl.mkl.generator

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import java.util.List
import br.com.kerubin.dsl.mkl.generator.test.JavaEntityServiceTestGenerator
import br.com.kerubin.dsl.mkl.generator.test.JavaEntityTestResourcesGenerator
import br.com.kerubin.dsl.mkl.generator.test.JavaEntityTestApplicationGenerator
import br.com.kerubin.dsl.mkl.generator.test.JavaEntityTestRepositoryGenerator
import br.com.kerubin.dsl.mkl.generator.test.JavaEntityBaseTestGenerator
import br.com.kerubin.dsl.mkl.generator.test.JavaEntityTestVisitorGenerator
import br.com.kerubin.dsl.mkl.generator.messaging.JavaServerMessagingGenerator

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
		
		var List<IGeneratorExecutor> generators = newArrayList(
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
			// new JavaObjectMapperGenerator(this),
			new JavaEntityDTOConverterGenerator(this),
			new JavaServiceConstantsGenerator(this),
			new JavaServiceConfigGenerator(this),
			new JavaClientPageResultGenerator(this),
			new JavaEntityControllerGenerator(this),
			new JavaPostgreSQLGenerator(this),
			new JavaServerHttpFilterGenerator(this),
			new JavaServiceHandlerInterceptorAdapterGenerator(this),
			new JavaServiceWebMvcConfigurerAdapterGenerator(this),
			new JavaMessagingAfterReceivePostProcessorsGenerator(this),
			new JavaEntityRuleFunctionsGenerator(this),		
			new JavaSwaggerConfigGenerator(this),
			new JavaMapConverterGenerator(this),
			new JavaServerMessagingGenerator(this)
		)
		
		if (canGenerateServiceBackendTest) {
			generators.add(new JavaEntityTestApplicationGenerator(this))
			generators.add(new JavaEntityBaseTestGenerator(this))
			generators.add(new JavaEntityServiceTestGenerator(this))
			generators.add(new JavaEntityTestRepositoryGenerator(this))
			generators.add(new JavaEntityTestResourcesGenerator(this))
			generators.add(new JavaEntityTestVisitorGenerator(this))
		}
		
		generators.forEach[it.generate]	 
	}
	
}