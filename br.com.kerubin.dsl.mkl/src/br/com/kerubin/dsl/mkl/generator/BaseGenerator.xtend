package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Configuration
import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Enumeration
import br.com.kerubin.dsl.mkl.model.Service
import java.time.LocalDateTime
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.osgi.framework.FrameworkUtil

abstract class BaseGenerator {
	
	protected Resource resource
	protected IFileSystemAccess2 fsa
	protected Service service
	protected Configuration configuration
	protected Iterable<Entity> entities
	protected Iterable<Enumeration> enums
	
	protected var bundleVersion = null
	
	protected var String codeGenerationHeader = null
	
	ServiceBooster serviceBooster
	
	new(Resource resource, IFileSystemAccess2 fsa) {
		this.resource = resource
		this.fsa = fsa
		
		service = resource.allContents.filter(Service).head
		configuration = service.configuration
		entities = service.elements.filter(Entity)
		enums = service.elements.filter(Enumeration)
		
		injectServiteBooster();
		serviceBooster.augmentService(service)
	}
	
	def getBundleVersion() {
		if (bundleVersion === null) {
			/*val bundle = Platform.getBundle("br.com.kerubin.dsl.mkl");
			val version = bundle?.getVersion() ?: "x";
			println(version)*/
			
			try {
				bundleVersion = FrameworkUtil.getBundle(getClass())?.getVersion() ?: "0.0.0";
			} catch(Exception e) {
				println("MKL Plug-in: Error at getBundleVersion: " + e.message)
				bundleVersion = null
			}
		}
		
		bundleVersion
	}
	
	private def void injectServiteBooster() {
		serviceBooster = new ServiceBoosterImpl();
	}
	
	protected def boolean canGenerateService() {
		!service.generationDisabled
	}
	
	protected def boolean canGenerateServiceBackend() {
 		service.canGenerateBackend
	}
	
	protected def boolean canGenerateServiceFrontend() {
		service.canGenerateFrontend
	}
	
	
	def generateFile(String fileName, CharSequence contents) {
		/*if (outputConfig === null) {
			outputConfig = (fsa as AbstractFileSystemAccess).outputConfigurations.get(IFileSystemAccess.DEFAULT_OUTPUT)
			//outputConfig.outputDirectory = OUTPUT_DIRECTORY
		}*/
		
		var contents_ = contents
		if (fileName.endsWith('.java')) { // In Java files, add copy right header
			contents_ = getCodeGenerationHeader + contents
		}
		
		fsa.generateFile(fileName, contents_)
	}
	
	def String getCodeGenerationHeader() {
		if (codeGenerationHeader === null) {
			val version = getBundleVersion
			val header = new StringBuilder
			header.append('/**********************************************************************************************')
			header.append('\r\nCode generated with MKL Plug-in version: ')
			header.append(version)
			header.append('\r\nCode generated at time stamp: ')
			header.append(LocalDateTime.now)
			header.append('\r\nCopyright: Kerubin - logokoch@gmail.com\r\n')
			header.append('\r\nWARNING: DO NOT CHANGE THIS CODE BECAUSE THE CHANGES WILL BE LOST IN THE NEXT CODE GENERATION.\r\n')
			header.append('***********************************************************************************************/')
			header.append('\r\n\r\n')
			
			codeGenerationHeader = header.toString
		}
		codeGenerationHeader
	}
	
	def generateFile(String fileName, CharSequence contents, String outputConfigurationName) {
		fsa.generateFile(fileName, outputConfigurationName, contents)
	}
	
	
	
	abstract def void generate()
	
}