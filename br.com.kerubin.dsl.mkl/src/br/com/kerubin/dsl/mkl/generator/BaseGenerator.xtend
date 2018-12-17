package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Configuration
import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Service
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2

abstract class BaseGenerator {
	
	protected Resource resource
	protected IFileSystemAccess2 fsa
	protected Service service
	protected Configuration configuration
	protected Iterable<Entity> entities
	
	ServiceBooster serviceBooster
	
	new(Resource resource, IFileSystemAccess2 fsa) {
		this.resource = resource
		this.fsa = fsa
		
		service = resource.allContents.filter(Service).head
		configuration = service.configuration
		entities = service.elements.filter(Entity)
		
		injectServiteBooster();
		serviceBooster.augmentService(service)
	}
	
	private def void injectServiteBooster() {
		serviceBooster = new ServiceBoosterImpl();
	}
	
	
	
	def generateFile(String fileName, CharSequence contents) {
		/*if (outputConfig === null) {
			outputConfig = (fsa as AbstractFileSystemAccess).outputConfigurations.get(IFileSystemAccess.DEFAULT_OUTPUT)
			//outputConfig.outputDirectory = OUTPUT_DIRECTORY
		}*/
		fsa.generateFile(fileName, contents)
	}
	
	def generateFile(String fileName, CharSequence contents, String outputConfigurationName) {
		fsa.generateFile(fileName, outputConfigurationName, contents)
	}
	
	
	
	abstract def void generate()
	
}