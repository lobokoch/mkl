package br.com.kerubin.dsl.mkl.generator

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2

class JavaGenerator extends BaseGenerator {
	
	new(Resource resource, IFileSystemAccess2 fsa) {
		super(resource, fsa)
	}
	
	override generate() {
		generateJavaFiles
	}
	
	def generateJavaFiles() {
		val IGeneratorExecutor[] generators = #[
			new JavaProjectsGenerator(this),
			new JavaServerConfigGenerator(this),
			new JavaEntityJPAGenerator(this),
			new JavaEntityRepositoryGenerator(this),
			new JavaEntityServiceGenerator(this),
			new JavaEntityDTOGenerator(this),
			new JavaEntityDTOConverterGenerator(this),
			new JavaClientPageResultGenerator(this),
			new JavaEntityControllerGenerator(this),
			new JavaPostgreSQLGenerator(this)
		]
		
		generators.forEach[it.generate]	 
	}
	
}