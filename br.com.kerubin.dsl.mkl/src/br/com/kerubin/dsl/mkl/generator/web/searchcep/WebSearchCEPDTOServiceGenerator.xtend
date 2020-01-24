package br.com.kerubin.dsl.mkl.generator.web.searchcep

import static br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.generator.GeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.IGeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.BaseGenerator

class WebSearchCEPDTOServiceGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	static val NAME = 'searchcepdto'
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val path = getWebSearchCEPDir 
		path.doGenerate
	}
	
	def doGenerate(String path) {
		val fullPath = path + '/' + NAME
		fullPath.generateService
	}
	
	def generateService(String name) {
		val fileName = name + '.ts'
		generateFile(fileName, generateSearchCEPDTO)
	}
	
	def CharSequence generateSearchCEPDTO() {
		'''
		// DTO do resultado da consulta em: https://viacep.com.br/
		export class SearchCEPDTO {
		  cep: string;
		  logradouro: string;
		  complemento: string;
		  bairro: string;
		  localidade: string;
		  uf: string;
		  unidade: string;
		  ibge: string;
		  gia: string;
			
		  // This element only exists if the cep could not be found.
		  erro: boolean;
		}
		
		'''
	}
	
	
}