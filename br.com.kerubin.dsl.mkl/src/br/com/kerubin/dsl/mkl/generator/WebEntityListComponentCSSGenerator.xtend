package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*

class WebEntityListComponentCSSGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[ entity |
			entity.generateComponentCSS
		]
	}
	
	def generateComponentCSS(Entity entity) {
		val path = entity.webEntityPath
		val entityFile = path + entity.toEntityWebListComponentName + '.css'
		generateFile(entityFile, entity.doGenerateEntityComponentCSS)
	}
	
	def CharSequence doGenerateEntityComponentCSS(Entity entity) {
		'''
		/* Write your CSS here. */
		
		'''
	}
	
}