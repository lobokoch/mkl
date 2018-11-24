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
			new WebEntityComponentGenerator(this)/*,
			new JavaEntityJPAGenerator(this),
			new JavaEntityRepositoryGenerator(this),
			new JavaEntityServiceGenerator(this),
			new JavaEntityDTOGenerator(this),			
			new JavaEnumGenerator(this),
			new JavaEntityLookupResultDTOGenerator(this),
			new JavaEntityListFilterGenerator(this),
			new JavaEntityAutoCompleteGenerator(this),
			new JavaEntityDTOConverterGenerator(this),
			new JavaClientPageResultGenerator(this),
			new JavaEntityControllerGenerator(this),
			new JavaPostgreSQLGenerator(this)*/
		]
		
		generators.forEach[it.generate]	 
	}
	
}