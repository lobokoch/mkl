package br.com.kerubin.dsl.mkl.generator.web.searchcep

import static br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.generator.GeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.IGeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.BaseGenerator

class WebSearchCEPServiceGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	public static val SERVICE_NAME = 'searchcep.service'
	public static val SERVICE_CLASS_NAME = 'SearchCEPService'
	
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
		val fullPath = path + '/' + SERVICE_NAME
		fullPath.generateService
	}
	
	def generateService(String name) {
		val fileName = name + '.ts'
		generateFile(fileName, generateSearchCEPService)
	}
	
	def CharSequence generateSearchCEPService() {
		'''
		import { SearchCEPDTO } from './searchcepdto';
		import { HttpClient } from '@angular/common/http';
		import { Injectable } from '@angular/core';
		
		@Injectable()
		export class «SERVICE_CLASS_NAME» {
		
		  URL_PREFIX = 'https://viacep.com.br/ws/';
		  URL_SUFIX = '/json/';
		
		  constructor(
		    private http: HttpClient
		    ) {
		
		    }
		
		    searchCEP(cep: string): Promise<SearchCEPDTO> {
		      const valid = cep && cep.trim().length === 8;
		      if (!valid) {
		        return Promise.resolve(this.newSearchCEPDTO(cep));
		      }
		
		      return this.http.get<SearchCEPDTO>(`${this.URL_PREFIX}${cep}${this.URL_SUFIX}`)
		      .toPromise()
		      .then(response => {
		        if (!response.hasOwnProperty('erro')) {
		          const result = response as SearchCEPDTO;
		          return result;
		        } else {
		          console.log('CEP not found: ' + cep);
		        return Promise.resolve(this.newSearchCEPDTO(cep));
		        }
		      })
		      .catch(error => {
		        console.log('Error in searchCEP: ' + error);
		        return Promise.resolve(this.newSearchCEPDTO(cep));
		      });
		    }
		
		    private newSearchCEPDTO(cep: string): SearchCEPDTO {
		      const dto = new SearchCEPDTO();
		      dto.cep = cep;
		      dto.erro = true;
		      return dto;
		    }
		}
		
		'''
	}
	
	
}